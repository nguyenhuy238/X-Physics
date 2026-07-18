import {
  IsArray,
  IsBoolean,
  IsISO8601,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

class SyncProgressItemDto {
  @IsString()
  lessonId!: string;

  @IsInt()
  @Min(0)
  @Max(100)
  progressPercent!: number;

  @IsOptional()
  @IsBoolean()
  isCompleted?: boolean;

  @IsOptional()
  @IsString()
  operationId?: string;

  @IsOptional()
  @IsObject()
  quizAttempt?: Record<string, unknown>;

  @IsISO8601()
  clientUpdatedAt!: string;
}

export class SyncProgressDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncProgressItemDto)
  items!: SyncProgressItemDto[];
}
