export const adminChapters = [
  { id: 1, title: "Chuyển động cơ học", order: 1, lessonsCount: 5, created: "01/05/2026", status: "published" },
  { id: 2, title: "Lực và áp suất", order: 2, lessonsCount: 4, created: "05/05/2026", status: "published" },
  { id: 3, title: "Điện học cơ bản", order: 3, lessonsCount: 6, created: "10/05/2026", status: "published" },
  { id: 4, title: "Quang học", order: 4, lessonsCount: 3, created: "20/05/2026", status: "draft" },
  { id: 5, title: "Nhiệt học", order: 5, lessonsCount: 0, created: "01/06/2026", status: "draft" },
];

export const adminLessons = [
  { id: 1, title: "Chuyển động đều", chapterId: 1, chapter: "Chuyển động cơ học", summary: "Khái niệm cơ bản về chuyển động đều", minutes: 10, status: "published", created: "02/05/2026" },
  { id: 2, title: "Vận tốc trung bình", chapterId: 1, chapter: "Chuyển động cơ học", summary: "Tính vận tốc trung bình qua quãng đường và thời gian", minutes: 12, status: "published", created: "03/05/2026" },
  { id: 3, title: "Chuyển động không đều", chapterId: 1, chapter: "Chuyển động cơ học", summary: "Phân biệt chuyển động đều và không đều", minutes: 15, status: "published", created: "04/05/2026" },
  { id: 4, title: "Lực là gì?", chapterId: 2, chapter: "Lực và áp suất", summary: "Định nghĩa và tác dụng của lực", minutes: 8, status: "published", created: "06/05/2026" },
  { id: 5, title: "Áp suất chất lỏng", chapterId: 2, chapter: "Lực và áp suất", summary: "Công thức tính áp suất p = F/S", minutes: 12, status: "draft", created: "07/05/2026" },
  { id: 6, title: "Cường độ dòng điện", chapterId: 3, chapter: "Điện học cơ bản", summary: "Định luật Ohm và công thức I = U/R", minutes: 10, status: "published", created: "11/05/2026" },
  { id: 7, title: "Hiệu điện thế", chapterId: 3, chapter: "Điện học cơ bản", summary: "Khái niệm và đơn vị đo hiệu điện thế", minutes: 8, status: "draft", created: "12/05/2026" },
];

export const adminQuestions = [
  { id: 1, lessonId: 1, lesson: "Chuyển động đều", question: "Một vật chuyển động đều với v = 5 m/s trong 10 giây, quãng đường đi được là?", correct: "B. 50 m", difficulty: "easy", created: "02/05/2026" },
  { id: 2, lessonId: 1, lesson: "Chuyển động đều", question: "Đơn vị của vận tốc trong hệ SI là gì?", correct: "B. m/s", difficulty: "easy", created: "02/05/2026" },
  { id: 3, lessonId: 2, lesson: "Vận tốc trung bình", question: "Vật đi 100 m trong 20 giây, vận tốc trung bình là?", correct: "B. 5 m/s", difficulty: "medium", created: "03/05/2026" },
  { id: 4, lessonId: 2, lesson: "Vận tốc trung bình", question: "Tính tương đối của chuyển động có nghĩa là gì?", correct: "B. Phụ thuộc vật mốc", difficulty: "hard", created: "03/05/2026" },
  { id: 5, lessonId: 4, lesson: "Lực là gì?", question: "Lực nào sau đây là lực tiếp xúc?", correct: "A. Lực ma sát", difficulty: "medium", created: "06/05/2026" },
  { id: 6, lessonId: 6, lesson: "Cường độ dòng điện", question: "Hiệu điện thế 12V, điện trở 4Ω, cường độ dòng điện là?", correct: "C. 3 A", difficulty: "medium", created: "11/05/2026" },
];

export const adminStudents = [
  { id: 1, name: "Nguyễn Văn Nam", email: "nam@example.com", grade: "Lớp 8", lessons: 8, avgScore: 8.5, lastActive: "Hôm nay", streak: 7 },
  { id: 2, name: "Trần Thị Mai", email: "mai@example.com", grade: "Lớp 9", lessons: 12, avgScore: 9.2, lastActive: "Hôm nay", streak: 15 },
  { id: 3, name: "Lê Văn Hùng", email: "hung@example.com", grade: "Lớp 8", lessons: 5, avgScore: 6.8, lastActive: "Hôm qua", streak: 2 },
  { id: 4, name: "Phạm Thị Lan", email: "lan@example.com", grade: "Lớp 9", lessons: 15, avgScore: 7.5, lastActive: "2 ngày trước", streak: 0 },
  { id: 5, name: "Hoàng Minh Đức", email: "duc@example.com", grade: "Lớp 8", lessons: 3, avgScore: 5.5, lastActive: "3 ngày trước", streak: 0 },
];

export const activeUsersData = [
  { day: "T2", users: 45 },
  { day: "T3", users: 62 },
  { day: "T4", users: 58 },
  { day: "T5", users: 71 },
  { day: "T6", users: 89 },
  { day: "T7", users: 103 },
  { day: "CN", users: 76 },
];

export const difficultLessonsData = [
  { name: "Tính tương đối", avgScore: 5.2 },
  { name: "Áp suất chất lỏng", avgScore: 5.8 },
  { name: "Định luật Ohm", avgScore: 6.1 },
  { name: "Chuyển động KĐ", avgScore: 6.4 },
  { name: "Lực ma sát", avgScore: 6.9 },
];

export const recentActivity = [
  { id: 1, user: "Trần Thị Mai", action: "Hoàn thành bài kiểm tra", detail: "Chuyển động đều — 9.5/10", time: "5 phút trước", type: "quiz" },
  { id: 2, user: "Nguyễn Văn Nam", action: "Bắt đầu bài học", detail: "Vận tốc trung bình", time: "12 phút trước", type: "lesson" },
  { id: 3, user: "Lê Văn Hùng", action: "Đăng ký tài khoản", detail: "Lớp 8", time: "1 giờ trước", type: "register" },
  { id: 4, user: "Phạm Thị Lan", action: "Tải bài học offline", detail: "Lực là gì?", time: "2 giờ trước", type: "download" },
  { id: 5, user: "Hoàng Minh Đức", action: "Mở khóa huy hiệu", detail: "Nhà vật lý tập sự", time: "3 giờ trước", type: "badge" },
];
