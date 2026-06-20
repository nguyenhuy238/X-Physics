import { IsObject, IsOptional, IsString } from 'class-validator';

export class AdminContentDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;
}
