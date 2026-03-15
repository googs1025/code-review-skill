# 安全检查清单（按语言分类）

## 通用（所有语言）

### 输入验证
- [ ] 所有外部输入（HTTP 参数、环境变量、文件内容）是否有校验？
- [ ] 是否使用白名单而非黑名单验证？
- [ ] 路径是否有 path traversal 防护（`../` 攻击）？

### 认证与授权
- [ ] 权限检查是否在操作发生前（而非后）执行？
- [ ] 是否有越权访问风险（A 用户操作 B 用户数据）？
- [ ] Session/Token 是否有过期机制？

### 敏感信息
- [ ] 密码、API key、private key 是否被硬编码？
- [ ] 日志中是否可能打印敏感信息？
- [ ] 错误信息是否泄露内部实现细节？

### 依赖安全
- [ ] 新增依赖是否有已知 CVE？（可用 `npm audit`/`pip-audit`/`govulncheck`）
- [ ] 新增依赖的 License 是否与项目兼容？

---

## Go 特有

### 并发安全
- [ ] 多 goroutine 访问的共享变量是否有 mutex 保护？
- [ ] channel 操作是否可能死锁（无缓冲 + 双向等待）？
- [ ] goroutine 是否都有退出条件（防泄漏）？

### 常见漏洞
- [ ] `os/exec` 调用：命令参数是否经过清理（防命令注入）？
- [ ] `fmt.Sprintf` 拼接 SQL：是否使用参数化查询？
- [ ] `http.ServeFile` / `http.Dir`：是否有路径逃逸风险？
- [ ] 整数溢出：`int` 用于长度/偏移量时是否有边界检查？

---

## Python 特有

### 常见漏洞
- [ ] `eval()` / `exec()` 是否被用于处理外部输入？
- [ ] `pickle.loads()` 是否处理了不可信数据？
- [ ] SQL 查询是否使用参数化（`cursor.execute("... %s", (val,))`）？
- [ ] YAML 是否使用 `yaml.safe_load()` 而非 `yaml.load()`？

### 依赖
- [ ] `requirements.txt` 是否固定了版本号（防供应链攻击）？

---

## JavaScript/TypeScript 特有

### 常见漏洞
- [ ] 用户输入是否被插入 DOM（防 XSS）？使用 `textContent` 而非 `innerHTML`
- [ ] `JSON.parse()` 是否有 try-catch？
- [ ] `eval()` / `Function()` 是否处理外部输入？
- [ ] CORS 配置是否过于宽松（`Access-Control-Allow-Origin: *`）？

### Node.js
- [ ] `child_process.exec()` 是否传入了未清理的输入？
- [ ] 路径拼接是否使用 `path.join()` 而非字符串拼接？

---

## Rust 特有

### 安全性
- [ ] `unsafe` 块是否有必要？是否有替代的安全写法？
- [ ] FFI 边界处是否正确处理了空指针和生命周期？
- [ ] 整数转换是否使用了 `checked_*` 或 `saturating_*`？

---

## Java/Kotlin 特有

### 常见漏洞
- [ ] 反序列化：是否使用了不可信数据源（防 Java deserialization attack）？
- [ ] XML 解析：是否禁用了外部实体（防 XXE）？
- [ ] SQL：是否使用 `PreparedStatement` 而非字符串拼接？
- [ ] 日志：是否有 Log4Shell 风险（`${jndi:...}` 注入）？
