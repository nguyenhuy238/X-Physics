export class AdminUserItemDto {
  id!: string;
  name!: string;
  email!: string;
  role!: 'STUDENT' | 'TEACHER' | 'ADMIN';
  coins!: number;
}

export class AdminUserListResponseDto {
  items!: AdminUserItemDto[];
  total!: number;
  page!: number;
  limit!: number;
}

export class AdminChapterItemDto {
  id!: string;
  title!: string;
  description!: string;
  orderIndex!: number;
  isPublished!: boolean;
  lessonCount?: number;
}

export class AdminLessonItemDto {
  id!: string;
  chapterId!: string;
  title!: string;
  contentMarkdown!: string;
  formulaLatex?: string;
  estimatedMinutes!: number;
  orderIndex!: number;
  isPublished!: boolean;
  questionCount?: number;
}

export class AdminQuestionItemDto {
  id!: string;
  lessonId!: string;
  question!: string;
  options!: string[];
  correctOption!: number;
  explanation!: string;
  difficulty?: 'EASY' | 'MEDIUM' | 'HARD';
  orderIndex!: number;
}

export class DifficultLessonDto {
  lessonId!: string;
  chapterId!: string;
  title!: string;
  wrongCount!: number;
}

export class ActiveTrendPointDto {
  date!: string;
  activeStudents!: number;
}

export class CompletionByChapterDto {
  chapterId!: string;
  title!: string;
  completedCount!: number;
  totalLessons!: number;
  completionRate!: number;
}

export class CompletionByLessonDto {
  lessonId!: string;
  chapterId!: string;
  title!: string;
  completedCount!: number;
  completionRate!: number;
}

export class AdminStatisticsResponseDto {
  activeStudents!: number;
  completionRate!: number;
  totalBadgesAwarded!: number;
  activeTrend!: ActiveTrendPointDto[];
  completionByChapter!: CompletionByChapterDto[];
  completionByLesson!: CompletionByLessonDto[];
  difficultLessons!: DifficultLessonDto[];
}

export class AdminQuizAttemptItemDto {
  id!: string;
  userId!: string;
  userName!: string;
  userEmail!: string;
  lessonId!: string;
  lessonTitle!: string;
  score!: number;
  correctCount!: number;
  totalQuestions!: number;
  durationSeconds!: number;
  coinsEarned!: number;
  createdAt!: string;
}

export class AdminQuizAttemptListResponseDto {
  items!: AdminQuizAttemptItemDto[];
  total!: number;
  page!: number;
  limit!: number;
}

