# API Contract Rules

- Moi endpoint phai co method, path, auth requirement, request body va response mau.
- Response phai theo envelope trong `API_RESPONSE_STANDARD.md`.
- Field JSON dung `camelCase`.
- Khong doi ten field da dung tren Flutter neu chua bao team.
- Neu can breaking change, tao PR docs truoc va tag tat ca module owner.
- Backend co the them field moi neu khong pha client hien tai.
- Flutter phai parse an toan khi field optional.
- Error validation phai tra `errors[]` voi `field` va `message`.
- Endpoint list phai co pagination khi du lieu co the lon.
