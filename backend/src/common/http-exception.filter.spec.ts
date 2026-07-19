import { ArgumentsHost, BadRequestException } from "@nestjs/common";

import { HttpExceptionFilter } from "./http-exception.filter";

describe("HttpExceptionFilter", () => {
  it("preserves structured field errors from http exceptions", () => {
    const json = jest.fn();
    const status = jest.fn(() => ({ json }));
    const host = {
      switchToHttp: () => ({
        getResponse: () => ({ status }),
      }),
    } as unknown as ArgumentsHost;
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
});
