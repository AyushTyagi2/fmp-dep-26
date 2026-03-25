namespace FmpBackend.Models;

public class Role
{
    public Guid   Id          { get; set; }
    public string Name        { get; set; } = null!;   // e.g. FLEET_OWNER, DRIVER
    public string DisplayName { get; set; } = null!;
}