using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace FmpBackend.Migrations
{
    /// <inheritdoc />
    public partial class SeedSystemRules : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "SystemRules",
                columns: new[] { "Id", "Description", "IsEnabled", "RuleKey", "UpdatedAt", "UpdatedBy", "Value" },
                values: new object[,]
                {
                    { new Guid("11111111-1111-1111-1111-111111111111"), "Automatically assign unassigned jobs to the closest available driver within 5km.", true, "AutoAssignDriver", new DateTime(2026, 3, 17, 15, 58, 0, 766, DateTimeKind.Utc).AddTicks(5609), null, null },
                    { new Guid("22222222-2222-2222-2222-222222222222"), "Enforce strict matching of vehicle type requested by sender.", true, "StrictVehicleRequirement", new DateTime(2026, 3, 17, 15, 58, 0, 766, DateTimeKind.Utc).AddTicks(5643), null, null },
                    { new Guid("33333333-3333-3333-3333-333333333333"), "Allow dispatchers to manually override system routing.", false, "AllowManualOverride", new DateTime(2026, 3, 17, 15, 58, 0, 766, DateTimeKind.Utc).AddTicks(5650), null, null },
                    { new Guid("44444444-4444-4444-4444-444444444444"), "Enable surge multiplier during high demand hours.", true, "DynamicSurgePricing", new DateTime(2026, 3, 17, 15, 58, 0, 766, DateTimeKind.Utc).AddTicks(5656), null, "1.5x max" },
                    { new Guid("55555555-5555-5555-5555-555555555555"), "Automatically process driver payouts at end of day.", false, "AutoSettlement", new DateTime(2026, 3, 17, 15, 58, 0, 766, DateTimeKind.Utc).AddTicks(5661), null, null },
                    { new Guid("66666666-6666-6666-6666-666666666666"), "Require manual approval of all new driver KYC documents.", true, "StrictKYC", new DateTime(2026, 3, 17, 15, 58, 0, 766, DateTimeKind.Utc).AddTicks(5667), null, null },
                    { new Guid("77777777-7777-7777-7777-777777777777"), "Require two-factor authentication for all system administrator actions.", true, "Force2FA", new DateTime(2026, 3, 17, 15, 58, 0, 766, DateTimeKind.Utc).AddTicks(5672), null, null }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "SystemRules",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"));

            migrationBuilder.DeleteData(
                table: "SystemRules",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"));

            migrationBuilder.DeleteData(
                table: "SystemRules",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"));

            migrationBuilder.DeleteData(
                table: "SystemRules",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"));

            migrationBuilder.DeleteData(
                table: "SystemRules",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"));

            migrationBuilder.DeleteData(
                table: "SystemRules",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"));

            migrationBuilder.DeleteData(
                table: "SystemRules",
                keyColumn: "Id",
                keyValue: new Guid("77777777-7777-7777-7777-777777777777"));
        }
    }
}
