import { IsOptional, IsString } from 'class-validator';

export class StatisticsQueryDto {
  @IsOptional()
  @IsString()
  from?: string;

  @IsOptional()
  @IsString()
  to?: string;
}
