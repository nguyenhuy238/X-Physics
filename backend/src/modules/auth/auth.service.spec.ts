import { ConflictException, UnauthorizedException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { JwtService } from "@nestjs/jwt";
import * as bcrypt from "bcrypt";

import { DatabaseRepository } from "../../database/database.repository";
import { AuthService } from "./auth.service";

describe("AuthService", () => {
  type CreateUserInput = {
    name: string;
    email: string;
    passwordHash: string;
    role?: "STUDENT" | "TEACHER" | "ADMIN";
  };

  const accessSecret = "test-access-secret";
  const refreshSecret = "test-refresh-secret";
  const publicUser = {
    id: "user-1",
    name: "Nguyen Van Nam",
    email: "nam@example.com",
    role: "STUDENT" as const,
    coins: 0,
  };

  const makeService = (overrides: Partial<DatabaseRepository> = {}) => {
    const createdUsers: CreateUserInput[] = [];
    const database = {
      findUserByEmail: jest.fn(),
      findUserById: jest.fn(),
      createUser: jest.fn(async (input: CreateUserInput) => {
        createdUsers.push(input);
        return {
          ...publicUser,
          name: input.name,
          email: input.email,
          passwordHash: input.passwordHash,
        };
      }),
      saveRefreshToken: jest.fn(),
      clearRefreshToken: jest.fn(),
      toPublicUser: jest.fn((user: typeof publicUser) => ({
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        coins: user.coins,
      })),
      ...overrides,
    } as unknown as DatabaseRepository;
    const jwtService = {
      signAsync: jest.fn(
        async (payload: { id: string }, options: { secret?: string }) =>
          options.secret === accessSecret
            ? `access:${payload.id}`
            : `refresh:${payload.id}`,
      ),
      verifyAsync: jest.fn(),
    } as unknown as JwtService;
    const configService = {
      get: jest.fn((key: string) =>
        key === "JWT_ACCESS_SECRET" ? accessSecret : refreshSecret,
      ),
    };

    return {
      service: new AuthService(
        database,
        jwtService,
        configService as unknown as ConfigService,
      ),
      database: database as unknown as {
        findUserByEmail: jest.Mock;
        findUserById: jest.Mock;
        createUser: jest.Mock;
        saveRefreshToken: jest.Mock;
        clearRefreshToken: jest.Mock;
      },
      jwtService: jwtService as unknown as {
        signAsync: jest.Mock;
        verifyAsync: jest.Mock;
      },
      createdUsers,
    };
  };

  it("registers a student with normalized email and hashed password", async () => {
    const { service, database, createdUsers } = makeService();
    database.findUserByEmail.mockResolvedValue(null);

    const result = await service.register({
      name: "  Nguyen Van Nam  ",
      email: "  NAM@EXAMPLE.COM ",
      password: "123456",
    });

    expect(database.findUserByEmail).toHaveBeenCalledWith("nam@example.com");
    expect(createdUsers[0].name).toBe("Nguyen Van Nam");
    expect(createdUsers[0].email).toBe("nam@example.com");
    expect(createdUsers[0].passwordHash).not.toBe("123456");
    await expect(
      bcrypt.compare("123456", createdUsers[0].passwordHash),
    ).resolves.toBe(true);
    expect(result.user).toEqual({
      ...publicUser,
      name: "Nguyen Van Nam",
      email: "nam@example.com",
    });
    expect(result.accessToken).toBe("access:user-1");
    expect(result.refreshToken).toBe("refresh:user-1");
  });

  it("rejects duplicate registration emails", async () => {
    const { service, database } = makeService();
    database.findUserByEmail.mockResolvedValue({
      ...publicUser,
      passwordHash: "hash",
    });

    await expect(
      service.register({
        name: "Nam",
        email: "nam@example.com",
        password: "123456",
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it("logs in with normalized email when the password matches", async () => {
    const passwordHash = await bcrypt.hash("123456", 10);
    const { service, database } = makeService();
    database.findUserByEmail.mockResolvedValue({ ...publicUser, passwordHash });

    const result = await service.login({
      email: " NAM@EXAMPLE.COM ",
      password: "123456",
    });

    expect(database.findUserByEmail).toHaveBeenCalledWith("nam@example.com");
    expect(result.user.email).toBe("nam@example.com");
    expect(result.accessToken).toBe("access:user-1");
  });

  it("rejects invalid login credentials", async () => {
    const passwordHash = await bcrypt.hash("123456", 10);
    const { service, database } = makeService();
    database.findUserByEmail.mockResolvedValue({ ...publicUser, passwordHash });

    await expect(
      service.login({ email: "nam@example.com", password: "wrong-password" }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it("refreshes tokens when refresh token is valid", async () => {
    const { service, database, jwtService } = makeService();
    const refreshToken = "valid-refresh";
    const refreshTokenHash = await bcrypt.hash(refreshToken, 10);
    jwtService.verifyAsync.mockResolvedValue({
      id: publicUser.id,
      email: publicUser.email,
      role: publicUser.role,
    });
    database.findUserById.mockResolvedValue({
      ...publicUser,
      passwordHash: "hash",
      refreshTokenHash,
      refreshTokenExpiresAt: new Date(Date.now() + 60_000),
    });

    const result = await service.refresh({ refreshToken });

    expect(jwtService.verifyAsync).toHaveBeenCalledWith(refreshToken, {
      secret: refreshSecret,
    });
    expect(result).toEqual({
      accessToken: "access:user-1",
      refreshToken: "refresh:user-1",
    });
  });
});
