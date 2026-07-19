import { BadRequestException, ValidationPipe } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";

import { AppModule } from "./app.module";
import { HttpExceptionFilter } from "./common/http-exception.filter";

type ValidationErrorShape = {
  property?: string;
  constraints?: Record<string, string>;
  children?: ValidationErrorShape[];
};

function flattenValidationErrors(
  errors: ValidationErrorShape[],
  parent = "",
): Array<{ field: string; message: string }> {
  return errors.flatMap((error) => {
    const field =
      parent && error.property
        ? `${parent}.${error.property}`
        : (error.property ?? parent);
    const ownErrors = Object.entries(error.constraints ?? {}).map(
      ([constraint, message]) => ({
        field,
        message: validationMessage(field, constraint, message),
      }),
    );
    const childErrors = flattenValidationErrors(error.children ?? [], field);
    return [...ownErrors, ...childErrors];
  });
}

function validationMessage(
  field: string,
  constraint: string,
  fallback: string,
) {
  const labels: Record<string, string> = {
    name: "Họ tên",
    email: "Email",
    password: "Mật khẩu",
    confirmPassword: "Xác nhận mật khẩu",
    currentPassword: "Mật khẩu hiện tại",
    newPassword: "Mật khẩu mới",
    confirmNewPassword: "Xác nhận mật khẩu mới",
  };
  const label = labels[field] ?? field;
  if (constraint === "isEmail") {
    return "Email không đúng định dạng.";
  }
  if (constraint === "isNotEmpty") {
    return `${label} không được để trống.`;
  }
  if (constraint === "isString") {
    return `${label} không hợp lệ.`;
  }
  if (constraint === "minLength") {
    return `${label} phải có ít nhất 6 ký tự.`;
  }
  if (constraint === "maxLength") {
    return `${label} vượt quá độ dài cho phép.`;
  }
  if (constraint === "whitelistValidation") {
    return `${label} không được phép gửi lên hệ thống.`;
  }
  return fallback;
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({
    origin: (origin, callback) => {
      if (!origin) {
        callback(null, true);
        return;
      }
      const allowedOrigins = (process.env.CORS_ORIGIN ?? "")
        .split(",")
        .map((item) => item.trim())
        .filter(Boolean);
      const isLocalhost = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(
        origin,
      );
      callback(null, isLocalhost || allowedOrigins.includes(origin));
    },
    credentials: true,
    methods: ["GET", "HEAD", "PUT", "PATCH", "POST", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  });
  app.setGlobalPrefix("api");
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      exceptionFactory: (errors) =>
        new BadRequestException({
          message: "Validation failed",
          errors: flattenValidationErrors(errors),
        }),
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());

  const config = new DocumentBuilder()
    .setTitle("X-Physics API")
    .setDescription("REST API contract for X-Physics")
    .setVersion("0.1.0")
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup("api/docs", app, document);

  await app.listen(process.env.PORT ?? 3000);
}

void bootstrap();
