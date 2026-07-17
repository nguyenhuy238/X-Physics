import { NotFoundException } from "@nestjs/common";

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
});
