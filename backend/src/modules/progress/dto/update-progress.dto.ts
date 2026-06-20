import { IsInt, IsString, Max, Min } from 'class-validator';

export class UpdateProgressDto {
  @IsString()
  lessonId!: string;

  @IsString()
  status!: 'NOT_STARTED' | 'IN_PROGRESS' | 'COMPLETED';

  @IsInt()
  @Min(0)
  @Max(100)
  progressPercent!: number;
}
