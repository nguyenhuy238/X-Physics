import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class AdminChapterDto {
  @IsString()
  id!: string;

  @IsString()
  title!: string;

  @IsString()
  description!: string;

  @IsInt()
  @Min(0)
  orderIndex!: number;

  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class AdminLessonDto {
  @IsString()
  id!: string;

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
  estimatedMinutes!: number;

  @IsInt()
  @Min(0)
  orderIndex!: number;

  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class AdminQuestionDto {
  @IsString()
  id!: string;

  @IsString()
  lessonId!: string;

  @IsString()
  questionText!: string;

  @IsArray()
  @ArrayMinSize(4)
  @IsString({ each: true })
  options!: string[];

  @IsInt()
  @Min(0)
  @Max(3)
  correctOption!: number;

  @IsString()
  explanation!: string;

  @IsInt()
  @Min(0)
  orderIndex!: number;
}
