import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";

import { ApiResponseDto } from "../../common/api-response.dto";
import { AuthGuard } from "../../common/auth.guard";
import { AuthenticatedUser } from "../../common/current-user";
import { Roles } from "../../common/roles.decorator";
import { RolesGuard } from "../../common/roles.guard";
import { SubmitQuizDto } from "./dto/submit-quiz.dto";
import { QuizService } from "./quiz.service";

@Controller("quiz")
@UseGuards(AuthGuard, RolesGuard)
export class QuizController {
  constructor(private readonly quizService: QuizService) {}

  @Post("submit")
  @Roles("STUDENT")
  async submit(
    @Req() request: { user: AuthenticatedUser },
    @Body() dto: SubmitQuizDto,
  ) {
    return ApiResponseDto.ok(
      await this.quizService.submit(request.user, dto),
      "Submitted",
    );
  }

  @Get("attempts/me")
  async myAttempts(@Req() request: { user: AuthenticatedUser }) {
    return ApiResponseDto.ok(await this.quizService.myAttempts(request.user));
  }

  @Get("attempts/:id")
  async attempt(
    @Req() request: { user: AuthenticatedUser },
    @Param("id") id: string,
  ) {
    return ApiResponseDto.ok(await this.quizService.attempt(request.user, id));
  }
}
