# API Response Standard

## Success

```json
{
  "success": true,
  "message": "OK",
  "data": {}
}
```

## Error

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Email is invalid"
    }
  ]
}
```

## List/Pagination

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "items": [],
    "pageNumber": 1,
    "pageSize": 10,
    "totalItems": 100,
    "totalPages": 10
  }
}
```

## Rules

- HTTP 2xx van phai co `success: true`.
- HTTP 4xx/5xx phai co `success: false`.
- `message` ngan gon, co the hien thi cho user neu phu hop.
- `errors` dung cho validation field-level.
- Khong doi envelope response neu chua thong nhat.
