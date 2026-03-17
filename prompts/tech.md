Tôi cần bạn nghiên cứu toàn diện về {{TECH_NAME}} ({{TECH_CATEGORY}}) và tạo bộ tài liệu markdown chi tiết, tách thành từng file riêng biệt để tải về.

## Bối cảnh

- **Hạ tầng:** Self-hosted Kubernetes RKE2, air-gapped
- **Use case:** GTEL Maps Platform
- **Data sources liên quan:**

## Đối tượng đọc

Tài liệu phải đáp ứng cho 2 nhóm:

1. **Giám đốc Công nghệ / CEO** — Executive summary, lý do chọn, chi phí, rủi ro, lộ trình triển khai
2. **Nhân viên kỹ thuật** — Kiến trúc chi tiết, cài đặt, cấu hình, vận hành, troubleshooting

### Phần A — Dành cho Leadership (3 files)

- **01-EXECUTIVE-SUMMARY.md** — {{TECH_NAME}} là gì, tại sao cần, lợi ích kinh doanh, rủi ro, chi phí
- **02-WHY-{{TECH_NAME}}.md** — So sánh với {{COMPARISON_CANDIDATES}} (hoặc tự đề xuất danh sách OSS phổ biến nhất cùng loại), phân tích license, weighted scoring matrix, TCO 3 năm
- **03-ROADMAP.md** — Lộ trình triển khai (Gantt chart), milestones, resource plan, risk register, KPIs

### Phần B — Dành cho Kỹ thuật (8-11 files, tùy công nghệ)

- **04-ARCHITECTURE.md** — Kiến trúc hệ thống, thành phần, data flow, internal mechanisms
- **05-DEPLOY-DOCKER.md** — Docker/Docker Compose setup cho development/testing
- **06-DEPLOY-KUBERNETES.md** — Helm chart, values.yaml production, Ingress, HPA, production checklist
- **07-DEPLOY-AIRGAPPED.md** — Triển khai offline trên RKE2, private registry, data sovereignty compliance
- **08-GUIDE-BASIC.md** — Hướng dẫn sử dụng cơ bản, concepts, getting started
- **09-GUIDE-ADVANCED.md** — Tính năng nâng cao, API, tích hợp, automation
- **10-SECURITY.md** — Authentication, authorization, encryption, hardening checklist
- **11-INTEGRATION.md** — Tích hợp với các hệ thống khác trong stack
- **12-PERFORMANCE.md** — Tuning, benchmarks, bottlenecks, scaling strategies
- **13-OPERATIONS.md** — Monitoring, backup/restore, upgrade, troubleshooting, diagnostic commands
- **14-APPENDIX.md** — Config templates production-ready, version history, glossary, tài liệu tham khảo

## Yêu cầu chất lượng

### Diagrams (BẮT BUỘC)

Mỗi file phải có **Mermaid diagrams** phù hợp:

- **Sequence Diagrams** cho mọi flow quan trọng (query execution, authentication, data pipeline, deployment process, backup/restore, upgrade...)
- **Architecture graphs** cho tổng quan hệ thống và quan hệ giữa components
- **ER diagrams** cho data models / schema
- **Gantt charts** cho lộ trình triển khai
- **Mindmaps** cho phân loại features/concepts
- **Flowcharts** cho decision trees, troubleshooting

Mục tiêu: **50+ diagrams** tổng cộng, trong đó **15-20 Sequence Diagrams**.

### Nội dung kỹ thuật

- Code blocks với config thực tế, copy-paste-ready
- Bảng so sánh có dữ liệu cụ thể (không chung chung)
- Connection strings, CLI commands, kubectl commands
- Production-ready config templates (không dùng default values)
- Troubleshooting table: Lỗi → Nguyên nhân → Giải pháp

### So sánh (file 02)

- So sánh ít nhất **1-5 công cụ** cùng category
- TCO 3 năm (license cost + infrastructure + operational)
- Community health: GitHub stars, contributors, release frequency, corporate backing

### Ngôn ngữ

Tiếng Việt, giữ nguyên thuật ngữ kỹ thuật tiếng Anh

## Output

Tạo từng file markdown riêng biệt, mỗi file là một section hoàn chỉnh, có thể đọc độc lập. File 00-INDEX.md là mục lục tổng với bảng routing theo đối tượng đọc.
