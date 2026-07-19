import { BadRequestException, NotFoundException } from "@nestjs/common";
import * as bcrypt from "bcrypt";

import { DatabaseRepository } from "../../database/database.repository";
import { UsersService } from "./users.service";

describe("UsersService", () => {
  const dbUser = {
    id: "user-1",
    name: "Nguyen Van Nam",
    email: "nam@example.com",
    passwordHash: "hash",
    role: "STUDENT" as const,
    coins: 20,
  };

  const makeService = () => {
    const database = {
      findUserById: jest.fn(),
      updateUser: jest.fn(),
      updatePassword: jest.fn(),
      toPublicUser: jest.fn((user: typeof dbUser) => ({
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        coins: user.coins,
      })),
    } as unknown as DatabaseRepository;
    return {
      service: new UsersService(database),
      database: database as unknown as {
        findUserById: jest.Mock;
        updateUser: jest.Mock;
        updatePassword: jest.Mock;
      },
    };
  };

  it("returns the current public user", async () => {
    const { service, database } = makeService();
    database.findUserById.mockResolvedValue(dbUser);

    await expect(service.me("user-1")).resolves.toEqual({
      id: "user-1",
      name: "Nguyen Van Nam",
      email: "nam@example.com",
      role: "STUDENT",
      coins: 20,
    });
  });

  it("throws when the current user no longer exists", async () => {
    const { service, database } = makeService();
    database.findUserById.mockResolvedValue(null);

    await expect(service.me("missing-user")).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it("trims profile name updates and returns a public user", async () => {
    const { service, database } = makeService();
    database.updateUser.mockResolvedValue({ ...dbUser, name: "Tran Binh" });

    const result = await service.updateMe("user-1", {
      name: "  Tran Binh  ",
    });

    expect(database.updateUser).toHaveBeenCalledWith("user-1", {
      name: "Tran Binh",
    });
    expect(result).toEqual({
      id: "user-1",
      name: "Tran Binh",
      email: "nam@example.com",
      role: "STUDENT",
      coins: 20,
    });
  });

  it("rejects password changes when the current password is wrong", async () => {
    const { service, database } = makeService();
    database.findUserById.mockResolvedValue({
      ...dbUser,
      passwordHash: await bcrypt.hash("123456", 10),
    });

    await expect(
      service.changePassword("user-1", {
        currentPassword: "wrong-password",
        newPassword: "654321",
        confirmNewPassword: "654321",
      }),
    ).rejects.toMatchObject({
      response: {
        errors: [
          {
            field: "currentPassword",
            message: "Mật khẩu hiện tại không đúng.",
          },
        ],
      },
    });
    expect(database.updatePassword).not.toHaveBeenCalled();
  });

  it("changes password only after validating the current password", async () => {
    const { service, database } = makeService();
    database.findUserById.mockResolvedValue({
      ...dbUser,
      passwordHash: await bcrypt.hash("123456", 10),
    });

    await expect(
      service.changePassword("user-1", {
        currentPassword: "123456",
        newPassword: "654321",
        confirmNewPassword: "654321",
      }),
    ).resolves.toEqual({ passwordChanged: true, requiresLogin: true });
    expect(database.updatePassword).toHaveBeenCalledTimes(1);
    await expect(
      bcrypt.compare("654321", database.updatePassword.mock.calls[0][1]),
    ).resolves.toBe(true);
  });

  it("returns field errors for invalid password change input", async () => {
    const { service, database } = makeService();
    database.findUserById.mockResolvedValue({
      ...dbUser,
      passwordHash: await bcrypt.hash("123456", 10),
    });

    await expect(
      service.changePassword("user-1", {
        currentPassword: "123456",
        newPassword: "654321",
        confirmNewPassword: "000000",
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(database.updatePassword).not.toHaveBeenCalled();
  });
});
