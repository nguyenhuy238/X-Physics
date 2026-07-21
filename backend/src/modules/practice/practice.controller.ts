import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";

import { ApiResponseDto } from "../../common/api-response.dto";
import { AuthGuard } from "../../common/auth.guard";
import { AuthenticatedUser } from "../../common/current-user";
import { Roles } from "../../common/roles.decorator";
import { RolesGuard } from "../../common/roles.guard";
import {
  PracticeQuestionQueryDto,
  SyncPracticeSessionsDto,
} from "./dto/sync-practice-sessions.dto";
import { PracticeService } from "./practice.service";

@Controller("lessons/:lessonId")
export class PracticeController {
  constructor(private readonly practiceService: PracticeService) {}

  @Get("practice-questions")
  async questions(
    @Param("lessonId") lessonId: string,
    @Query() query: PracticeQuestionQueryDto,
  ) {
    return ApiResponseDto.ok(
      await this.practiceService.questions(lessonId, query.offlineOnly),
    );
  }

  @Post("practice-sessions/sync")
  @UseGuards(AuthGuard, RolesGuard)
  @Roles("STUDENT")
  async syncSessions(
    @Req() request: { user: AuthenticatedUser },
    @Param("lessonId") lessonId: string,
    @Body() dto: SyncPracticeSessionsDto,
  ) {
    return ApiResponseDto.ok(
      await this.practiceService.syncSessions(request.user, lessonId, dto),
    );
  }
}
