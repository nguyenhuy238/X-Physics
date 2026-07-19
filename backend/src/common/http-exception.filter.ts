import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import { Response } from "express";

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
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
}
