namespace FmpBackend.Dtos
{
    /// <summary>
    /// Flattened trip representation returned to the Flutter fleet manager UI.
    /// All joins (vehicle, driver, shipment, addresses) are resolved server-side
    /// so the client receives a single, ready-to-render object.
    /// </summary>
    public class FleetTripDto
    {
        // ── Trip identity ──────────────────────────────────────────────────────
        public Guid   TripId        { get; set; }
        public string TripNumber    { get; set; } = string.Empty;
        public string CurrentStatus { get; set; } = string.Empty;

        // ── Schedule ───────────────────────────────────────────────────────────
        public DateTime? PlannedStartTime     { get; set; }
        public DateTime? ActualStartTime      { get; set; }
        public decimal?  EstimatedDistanceKm  { get; set; }

        // ── Vehicle & Driver (joined) ──────────────────────────────────────────
        public string VehicleRegistrationNumber { get; set; } = string.Empty;
        public string DriverName                { get; set; } = string.Empty;

        // ── Route (joined from shipment → addresses) ───────────────────────────
        public string PickupCity { get; set; } = string.Empty;
        public string DropCity   { get; set; } = string.Empty;

        // ── Cargo (joined from shipment) ───────────────────────────────────────
        public string  CargoType     { get; set; } = string.Empty;
        public decimal? CargoWeightKg { get; set; }
    }
}