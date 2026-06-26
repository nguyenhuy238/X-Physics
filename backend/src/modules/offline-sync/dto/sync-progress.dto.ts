import {
  IsArray,
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
  @IsObject()
  quizAttempt?: Record<string, unknown>;

  @IsString()
  clientUpdatedAt!: string;
}

export class SyncProgressDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncProgressItemDto)
  items!: SyncProgressItemDto[];
}
