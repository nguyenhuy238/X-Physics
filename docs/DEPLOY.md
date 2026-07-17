# Deploy Guide

## Backend

1. Tao repo backend tren Railway hoac Render.
2. Them bien moi truong:

| Bien | Gia tri |
| --- | --- |
| DATABASE_URL | PostgreSQL URL |
| JWT_ACCESS_SECRET | secret key |
| JWT_REFRESH_SECRET | refresh secret |
| CORS_ORIGIN | domain cua app |

3. Chay migration + seed:

```bash
npm run db:seed
```

4. Kiem tra Swagger tai `/api/docs`.

## Flutter

1. Build release APK/IPA.
2. Dung build tool ket noi production backend.
3. Test login admin va xem danh sach/chart.

## Production Checklist

- [ ] Backend chay tren Railway/Render.
- [ ] DB backup bat.
- [ ] Swagger/Postman collection cap nhat URL.
- [ ] Flutter build demo.
- [ ] App ket noi duoc API production.
- [ ] `POSTMAN` collection da day du endpoint admin.
- [ ] `docs/API_CONTRACT.md` trung voi endpoint thuc te.
