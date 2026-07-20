import { ArgumentsHost, BadRequestException } from "@nestjs/common";

import { HttpExceptionFilter } from "./http-exception.filter";

describe("HttpExceptionFilter", () => {
  function hostFor(json = jest.fn()) {
    const status = jest.fn(() => ({ json }));
    const host = {
      switchToHttp: () => ({
        getResponse: () => ({ status }),
      }),
    } as unknown as ArgumentsHost;
    return { host, status, json };
  }

  it("preserves structured field errors from http exceptions", () => {
    const { host, status, json } = hostFor();
    const exception = new BadRequestException({
      message: "Đổi mật khẩu thất bại.",
      errors: [
        {
          field: "currentPassword",
          message: "Mật khẩu hiện tại không đúng.",
        },
      ],
    });

    new HttpExceptionFilter().catch(exception, host);

    expect(status).toHaveBeenCalledWith(400);
    expect(json).toHaveBeenCalledWith({
      success: false,
      message: "Đổi mật khẩu thất bại.",
      errors: [
        {
          field: "currentPassword",
          message: "Mật khẩu hiện tại không đúng.",
        },
      ],
    });
  });

  it("maps PostgreSQL unique violations to 409 without raw database text", () => {
    const { host, status, json } = hostFor();

    new HttpExceptionFilter().catch(
      {
        code: "23505",
        constraint: "users_email_key",
        detail: "Key (email)=(test@example.com) already exists.",
      },
      host,
    );

    expect(status).toHaveBeenCalledWith(409);
    expect(json).toHaveBeenCalledWith({
      success: false,
      message: "Dữ liệu đã tồn tại trong hệ thống.",
    });
  });

  it("maps notification foreign key violations to a friendly 404", () => {
    const { host, status, json } = hostFor();

    new HttpExceptionFilter().catch(
      { code: "23503", constraint: "notifications_user_id_fkey" },
      host,
    );

    expect(status).toHaveBeenCalledWith(404);
    expect(json).toHaveBeenCalledWith({
      success: false,
      message: "Không tìm thấy học sinh.",
    });
  });

  it("maps check constraint violations to business messages", () => {
    const { host, status, json } = hostFor();

    new HttpExceptionFilter().catch(
      { code: "23514", constraint: "questions_correct_option_range" },
      host,
    );

    expect(status).toHaveBeenCalledWith(400);
    expect(json).toHaveBeenCalledWith({
      success: false,
      message: "Đáp án đúng phải nằm trong khoảng từ 0 đến 3.",
    });
  });
});
