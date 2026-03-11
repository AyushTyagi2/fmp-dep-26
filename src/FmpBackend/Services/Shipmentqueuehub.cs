using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace FmpBackend.Services;

/// <summary>
/// ✅ NEW: SignalR hub that replaces 5-second polling on the Flutter queue screens.
///
/// Flutter connects once:
///   final hub = HubConnectionBuilder().withUrl("/hubs/shipment-queue").build();
///   hub.on("NewShipmentAvailable", (dto) => _addToQueue(dto));
///   hub.on("ShipmentAccepted",     (id)  => _removeFromQueue(id));
///   await hub.start();
///
/// Events emitted by the server:
///   "NewShipmentAvailable"  → broadcast when a shipment is enqueued (after approval)
///   "ShipmentAccepted"      → broadcast when a driver accepts (remove from all clients' lists)
/// </summary>
[Authorize]
public class ShipmentQueueHub : Hub
{
    /// <summary>
    /// Drivers call this to subscribe to a specific zone's updates only.
    /// If not called, client receives all zone updates.
    /// </summary>
    public async Task JoinZone(string zoneId)
        => await Groups.AddToGroupAsync(Context.ConnectionId, $"zone-{zoneId}");

    public async Task LeaveZone(string zoneId)
        => await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"zone-{zoneId}");
}