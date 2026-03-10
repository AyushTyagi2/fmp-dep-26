namespace FmpBackend.Dtos;

// ── Pagination ────────────────────────────────────────────────────────────────

public class PagedResult<T>
{
    public IReadOnlyList<T> Items     { get; init; } = [];
    public int              Total     { get; init; }
    public int              Page      { get; init; }
    public int              PageSize  { get; init; }
    public int TotalPages  => PageSize > 0 ? (int)Math.Ceiling((double)Total / PageSize) : 0;
    public bool HasNextPage => Page < TotalPages;
    public bool HasPrevPage => Page > 1;
}