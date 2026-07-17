import { IsOptional, IsString } from 'class-validator';

export class RecordDownloadDto {
  @IsString()
  lessonId!: string;

  @IsOptional()
  @IsString()
  clientDeviceId?: string;
}
