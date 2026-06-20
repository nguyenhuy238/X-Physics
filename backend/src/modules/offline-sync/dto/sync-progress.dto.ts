import { IsArray, IsObject, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class SyncProgressItemDto {
  @IsString()
  lessonId!: string;

  @IsString()
  clientUpdatedAt!: string;

  @IsObject()
  payload!: Record<string, unknown>;
}

export class SyncProgressDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncProgressItemDto)
  items!: SyncProgressItemDto[];
}
