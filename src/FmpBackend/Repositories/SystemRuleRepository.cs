using FmpBackend.Data;
using FmpBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace FmpBackend.Repositories;

public class SystemRuleRepository
{
    private readonly AppDbContext _context;

    public SystemRuleRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<SystemRule>> GetAllRulesAsync()
    {
        return await _context.SystemRules.OrderBy(r => r.RuleKey).ToListAsync();
    }

    public async Task<SystemRule?> GetRuleByKeyAsync(string ruleKey)
    {
        return await _context.SystemRules.FirstOrDefaultAsync(r => r.RuleKey == ruleKey);
    }

    public async Task<SystemRule> UpdateRuleAsync(string ruleKey, bool isEnabled, string? value = null)
    {
        var rule = await GetRuleByKeyAsync(ruleKey);
        if (rule == null)
        {
            rule = new SystemRule
            {
                RuleKey = ruleKey,
                IsEnabled = isEnabled,
                Value = value,
                Description = $"Auto-generated rule for {ruleKey}"
            };
            _context.SystemRules.Add(rule);
        }
        else
        {
            rule.IsEnabled = isEnabled;
            if (value != null) rule.Value = value;
            rule.UpdatedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        return rule;
    }
}
