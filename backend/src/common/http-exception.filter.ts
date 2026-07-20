import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import { Response } from "express";

type PgError = {
  code?: string;
  constraint?: string;
};

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const databaseError = this.databaseErrorResponse(exception);
    if (databaseError) {
      response.status(databaseError.status).json(databaseError.body);
      return;
    }
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    const payload =
      exception instanceof HttpException ? exception.getResponse() : null;
    const payloadObject =
      typeof payload === "object" && payload
        ? (payload as Record<string, unknown>)
        : null;
    const payloadErrors = payloadObject?.errors;
    const validationMessages = payloadObject?.message;

    response.status(status).json({
      success: false,
      message:
        payloadObject && "message" in payloadObject
          ? payloadObject.message
          : "Internal server error",
      errors: Array.isArray(payloadErrors)
        ? payloadErrors
        : Array.isArray(validationMessages)
          ? validationMessages.map((message) => ({ message }))
          : undefined,
    });
  }

  private databaseErrorResponse(exception: unknown):
    | {
        status: number;
        body: {
          success: false;
          message: string;
          errors?: Array<{ message: string }>;
        };
      }
    | null {
    if (!this.isPgError(exception)) {
      return null;
    }

    if (exception.code === "23505") {
      return {
        status: HttpStatus.CONFLICT,
        body: {
          success: false,
          message: "Dữ liệu đã tồn tại trong hệ thống.",
        },
      };
    }

    if (exception.code === "23503") {
      const message =
        exception.constraint === "notifications_user_id_fkey"
          ? "Không tìm thấy học sinh."
          : "Dữ liệu liên kết không tồn tại.";
      return {
        status: HttpStatus.NOT_FOUND,
        body: { success: false, message },
      };
    }

    if (exception.code === "23514") {
      return {
        status: HttpStatus.BAD_REQUEST,
        body: {
          success: false,
          message: this.checkConstraintMessage(exception.constraint),
        },
      };
    }

    return null;
  }

  private isPgError(exception: unknown): exception is PgError {
    return (
      typeof exception === "object" &&
      exception !== null &&
      "code" in exception &&
      typeof (exception as PgError).code === "string"
    );
  }

  private checkConstraintMessage(constraint?: string) {
    const messages: Record<string, string> = {
      questions_correct_option_range:
        "Đáp án đúng phải nằm trong khoảng từ 0 đến 3.",
      questions_options_json_four_items:
        "Câu hỏi phải có đúng 4 đáp án.",
      quiz_attempts_score_range:
        "Điểm quiz phải nằm trong khoảng từ 0 đến 10.",
      quiz_attempts_counts_valid:
        "Số câu đúng và tổng số câu hỏi không hợp lệ.",
      quiz_attempts_duration_non_negative:
        "Thời lượng làm quiz không được âm.",
      quiz_attempts_coins_non_negative:
        "Số xu nhận được không được âm.",
      users_coins_non_negative:
        "Số xu của người dùng không được âm.",
    };
    return constraint && messages[constraint]
      ? messages[constraint]
      : "Dữ liệu không hợp lệ.";
  }
}
