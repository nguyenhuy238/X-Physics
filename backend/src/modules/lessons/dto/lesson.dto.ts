import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class LessonDto {
  @IsString()
  chapterId!: string;

  @IsString()
  title!: string;

  @IsString()
  contentMarkdown!: string;

  @IsOptional()
  @IsString()
  formulaLatex?: string;

  @IsInt()
  @Min(1)
  orderIndex!: number;
}
