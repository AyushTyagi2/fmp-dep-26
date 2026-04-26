using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FmpBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddPriorityRules : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "priority_rule",
                table: "queue_events",
                type: "text",
                nullable: false,
                defaultValue: "highest_trips");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "priority_rule",
                table: "queue_events");
        }
    }
}
