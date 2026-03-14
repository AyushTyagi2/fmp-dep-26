namespace FmpBackend.Models;

public class SystemRule
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    // E.g. "AutoAssignDriver", "DynamicSurgePricing"
    public string RuleKey { get; set; } = string.Empty;
    
    public string Description { get; set; } = string.Empty;
    public bool IsEnabled { get; set; } = false;
    
    // Optional parameter value (e.g. max skips = "3", surge = "1.5x")
    public string? Value { get; set; } 
    
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public string? UpdatedBy { get; set; } 
}
