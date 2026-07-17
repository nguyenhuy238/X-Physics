import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsEnum,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from "class-validator";
import { Transform, Type } from "class-transformer";

export enum QuestionDifficulty {
  EASY = "EASY",
  MEDIUM = "MEDIUM",
  HARD = "HARD",
}

export class AdminFormulaVariableDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^[A-Za-z_][A-Za-z0-9_]*$/)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  symbol!: string;

  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  label!: string;

  @IsString()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  unit!: string;

  @IsNumber()
  @Type(() => Number)
  min!: number;

  @IsNumber()
  @Type(() => Number)
  max!: number;

  @IsNumber()
  @Type(() => Number)
  step!: number;

  @IsNumber()
  @Type(() => Number)
  default!: number;
}

export class AdminFormulaResultDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^[A-Za-z_][A-Za-z0-9_]*$/)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  symbol!: string;

  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  label!: string;

  @IsString()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  unit!: string;

  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  expression!: string;

  @IsInt()
  @Min(0)
  @Max(6)
  @Type(() => Number)
  decimalPlaces!: number;
}

export class AdminFormulaSimulationDto {
  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  title!: string;

  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  formula!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => AdminFormulaVariableDto)
  variables!: AdminFormulaVariableDto[];

  @IsObject()
  @ValidateNested()
  @Type(() => AdminFormulaResultDto)
  result!: AdminFormulaResultDto;
}

export class AdminChapterDto {
  @IsString()
  @IsNotEmpty()
  @Length(3, 50)
  @Matches(/^[a-z0-9\-]+$/)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  id!: string;

  @IsString()
  @IsNotEmpty()
  @Length(3, 100)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  title!: string;

  @IsString()
  @IsNotEmpty()
  @Length(5, 500)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  description!: string;

  @IsInt()
  @Min(0)
  @Type(() => Number)
  orderIndex!: number;

  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class AdminLessonDto {
  @IsString()
  @IsNotEmpty()
  @Length(3, 50)
  @Matches(/^[a-z0-9\-]+$/)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  id!: string;

  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  chapterId!: string;

  @IsString()
  @IsNotEmpty()
  @Length(3, 100)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  title!: string;

  @IsString()
  @IsNotEmpty()
  @Length(10, 10000)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  contentMarkdown!: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  formulaLatex?: string;

  @IsInt()
  @Min(1)
  @Max(180)
  @Type(() => Number)
  estimatedMinutes!: number;

  @IsInt()
  @Min(0)
  @Type(() => Number)
  orderIndex!: number;

  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;

  @IsOptional()
  @ValidateNested()
  @Type(() => AdminFormulaSimulationDto)
  simulation?: AdminFormulaSimulationDto | null;
}

export class CreateAdminQuestionDto {
  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  lessonId!: string;

  @IsNotEmpty()
  @Length(3, 1000)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  questionText!: string;

  @IsArray()
  @ArrayMinSize(4)
  @ArrayMaxSize(4)
  @IsString({ each: true })
  @Transform(({ value }) =>
    Array.isArray(value)
      ? value.map((item) => (typeof item === "string" ? item.trim() : item))
      : value,
  )
  options!: string[];

  @IsInt()
  @Min(0)
  @Max(3)
  @Type(() => Number)
  correctOption!: number;

  @IsString()
  @IsNotEmpty()
  @Length(3, 2000)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  explanation!: string;

  @IsEnum(QuestionDifficulty)
  @IsOptional()
  difficulty?: QuestionDifficulty;

  @IsInt()
  @Min(1)
  @Type(() => Number)
  orderIndex!: number;
}

export class UpdateAdminQuestionDto {
  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  lessonId!: string;

  @IsString()
  @IsNotEmpty()
  @Length(3, 1000)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  questionText!: string;

  @IsArray()
  @ArrayMinSize(4)
  @ArrayMaxSize(4)
  @IsString({ each: true })
  @Transform(({ value }) =>
    Array.isArray(value)
      ? value.map((item) => (typeof item === "string" ? item.trim() : item))
      : value,
  )
  options!: string[];

  @IsInt()
  @Min(0)
  @Max(3)
  @Type(() => Number)
  correctOption!: number;

  @IsString()
  @IsNotEmpty()
  @Length(3, 2000)
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  explanation!: string;

  @IsEnum(QuestionDifficulty)
  @IsOptional()
  difficulty?: QuestionDifficulty;

  @IsInt()
  @Min(1)
  @Type(() => Number)
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
  @IsIn(["createdAt", "name", "email"])
  sortBy?: "createdAt" | "name" | "email";

  @IsOptional()
  @IsString()
  @IsIn(["ASC", "DESC"])
  sortOrder?: "ASC" | "DESC";

  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  page?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  @Type(() => Number)
  limit?: number;
}

export class ReorderAdminQuestionsDto {
  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  lessonId!: string;

  @IsArray()
  @ArrayNotEmpty()
  @IsString({ each: true })
  @Transform(({ value }) =>
    Array.isArray(value)
      ? value.map((item) => (typeof item === "string" ? item.trim() : item))
      : value,
  )
  questionIds!: string[];
}

export class AdminQuestionQueryDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  lessonId?: string;

  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  chapterId?: string;

  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  search?: string;

  @IsOptional()
  @IsEnum(QuestionDifficulty)
  difficulty?: QuestionDifficulty;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  page?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  @Type(() => Number)
  limit?: number;
}

export class AdminQuizAttemptQueryDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  search?: string;

  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === "string" ? value.trim() : value))
  lessonId?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  page?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  @Type(() => Number)
  limit?: number;
}

export class CreateAdminQuizAttemptDto {
  @IsString()
  @IsNotEmpty()
  userId!: string;

  @IsString()
  @IsNotEmpty()
  lessonId!: string;

  @IsInt()
  @Min(0)
  @Max(10)
  @Type(() => Number)
  score!: number;

  @IsInt()
  @Min(0)
  @Type(() => Number)
  correctCount!: number;

  @IsInt()
  @Min(1)
  @Type(() => Number)
  totalQuestions!: number;

  @IsInt()
  @Min(0)
  @Type(() => Number)
  durationSeconds!: number;
}

export class UpdateAdminQuizAttemptDto {
  @IsInt()
  @Min(0)
  @Max(10)
  @Type(() => Number)
  score!: number;

  @IsInt()
  @Min(0)
  @Type(() => Number)
  correctCount!: number;

  @IsInt()
  @Min(1)
  @Type(() => Number)
  totalQuestions!: number;

  @IsInt()
  @Min(0)
  @Type(() => Number)
  durationSeconds!: number;
}
