import { IsInt, IsString, Min } from 'class-validator';

export class ChapterDto {
  @IsString()
  title!: string;

  @IsString()
  description!: string;

  @IsInt()
  @Min(1)
  orderIndex!: number;
}
