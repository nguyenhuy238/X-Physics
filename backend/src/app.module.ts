import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';

import { AdminModule } from './modules/admin/admin.module';
import { AuthModule } from './modules/auth/auth.module';
import { BadgesModule } from './modules/badges/badges.module';
import { DatabaseModule } from './database/database.module';
import { ChaptersModule } from './modules/chapters/chapters.module';
import { LessonsModule } from './modules/lessons/lessons.module';
import { OfflineSyncModule } from './modules/offline-sync/offline-sync.module';
import { PracticeModule } from './modules/practice/practice.module';
import { ProgressModule } from './modules/progress/progress.module';
import { QuestionsModule } from './modules/questions/questions.module';
import { QuizModule } from './modules/quiz/quiz.module';
import { SimulationsModule } from './modules/simulations/simulations.module';
import { StatisticsModule } from './modules/statistics/statistics.module';
import { UsersModule } from './modules/users/users.module';
import { NotificationsModule } from './modules/notifications/notifications.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    JwtModule.register({ global: true }),
    DatabaseModule,
    AuthModule,
    UsersModule,
    ChaptersModule,
    LessonsModule,
    SimulationsModule,
    QuestionsModule,
    QuizModule,
    PracticeModule,
    ProgressModule,
    BadgesModule,
    OfflineSyncModule,
    AdminModule,
    StatisticsModule,
    NotificationsModule,
  ],
})
export class AppModule {}
