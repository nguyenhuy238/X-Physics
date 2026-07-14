import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
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
  @MaxLength(1000)
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
  @MaxLength(2000)
  explanation!: string;

  @IsOptional()
  @IsIn(['EASY', 'MEDIUM', 'HARD'])
  difficulty?: 'EASY' | 'MEDIUM' | 'HARD';

  @IsInt()
  @Min(0)
  orderIndex!: number;
}

export class AdminUsersQueryDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(180)
  search?: string;

  @IsOptional()
  @IsString()
  @IsIn(['createdAt', 'name', 'email'])
  sortBy?: 'createdAt' | 'name' | 'email';

  @IsOptional()
  @IsString()
  @IsIn(['ASC', 'DESC'])
  sortOrder?: 'ASC' | 'DESC';

  @IsOptional()
  @IsInt()
  @Min(1)
  page?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}
