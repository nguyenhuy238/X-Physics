import {
  IsArray,
  IsBoolean,
  IsISO8601,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from "class-validator";
import { Transform, Type } from "class-transformer";

export class PracticeQuestionQueryDto {
  @IsOptional()
  @Transform(({ value }) => value === true || value === "true")
  @IsBoolean()
  offlineOnly?: boolean;
}

export class PracticeSessionAnswerDto {
  @IsString()
  questionId!: string;

  @IsInt()
  @Min(0)
  @Max(3)
  @Type(() => Number)
  selectedOption!: number;
}

export class SyncPracticeSessionItemDto {
  @IsString()
  id!: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PracticeSessionAnswerDto)
  answers?: PracticeSessionAnswerDto[];

  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  questionsAttempted?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  correctCount?: number;

  @IsISO8601()
  startedAt!: string;

  @IsISO8601()
  completedAt!: string;
}

export class SyncPracticeSessionsDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncPracticeSessionItemDto)
  items!: SyncPracticeSessionItemDto[];
}
