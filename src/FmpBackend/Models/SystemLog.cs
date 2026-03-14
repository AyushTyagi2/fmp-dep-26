namespace FmpBackend.Models;

public class SystemLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    
    // E.g. "INFO", "WARN", "ERROR"
    public string Level { get; set; } = "INFO";
    
    public string Message { get; set; } = string.Empty;
    
    // E.g. "auth-service", "rule-engine", "db-cluster"
    public string Component { get; set; } = "system";
    
    public string? SourceIp { get; set; }
}
