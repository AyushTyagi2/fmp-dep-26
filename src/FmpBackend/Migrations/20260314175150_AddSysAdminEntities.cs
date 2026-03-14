using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FmpBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddSysAdminEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "addresses",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    owner_type = table.Column<string>(type: "text", nullable: false),
                    owner_id = table.Column<Guid>(type: "uuid", nullable: false),
                    label = table.Column<string>(type: "text", nullable: true),
                    contact_person_name = table.Column<string>(type: "text", nullable: true),
                    contact_phone = table.Column<string>(type: "text", nullable: true),
                    address_line1 = table.Column<string>(type: "text", nullable: false),
                    address_line2 = table.Column<string>(type: "text", nullable: true),
                    landmark = table.Column<string>(type: "text", nullable: true),
                    city = table.Column<string>(type: "text", nullable: false),
                    state = table.Column<string>(type: "text", nullable: false),
                    postal_code = table.Column<string>(type: "text", nullable: false),
                    country = table.Column<string>(type: "text", nullable: false, defaultValue: "India"),
                    latitude = table.Column<decimal>(type: "numeric", nullable: true),
                    longitude = table.Column<decimal>(type: "numeric", nullable: true),
                    access_instructions = table.Column<string>(type: "text", nullable: true),
                    operating_hours = table.Column<string>(type: "text", nullable: true),
                    is_default = table.Column<bool>(type: "boolean", nullable: false),
                    is_active = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    updated_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_addresses", x => x.id);
                    table.CheckConstraint("valid_owner_type", "owner_type IN ('user', 'organization')");
                });

            migrationBuilder.CreateTable(
                name: "drivers",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    current_fleet_owner_id = table.Column<Guid>(type: "uuid", nullable: true),
                    license_number = table.Column<string>(type: "text", nullable: false),
                    license_type = table.Column<string>(type: "text", nullable: false),
                    license_expiry_date = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    status = table.Column<string>(type: "text", nullable: false),
                    availability_status = table.Column<string>(type: "text", nullable: false),
                    verified = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    average_rating = table.Column<decimal>(type: "numeric", nullable: false),
                    total_trips_completed = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_drivers", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "fleet_owners",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    business_name = table.Column<string>(type: "text", nullable: true),
                    business_type = table.Column<string>(type: "text", nullable: true),
                    business_contact_phone = table.Column<string>(type: "text", nullable: true),
                    business_contact_email = table.Column<string>(type: "text", nullable: true),
                    status = table.Column<string>(type: "text", nullable: false),
                    verified = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_fleet_owners", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "organizations",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "text", nullable: false),
                    organization_type = table.Column<string>(type: "text", nullable: false),
                    registration_number = table.Column<string>(type: "text", nullable: true),
                    primary_contact_name = table.Column<string>(type: "text", nullable: false),
                    pan_number = table.Column<string>(type: "text", nullable: true),
                    gst_number = table.Column<string>(type: "text", nullable: true),
                    primary_contact_phone = table.Column<string>(type: "text", nullable: false),
                    primary_contact_email = table.Column<string>(type: "text", nullable: true),
                    industry = table.Column<string>(type: "text", nullable: true),
                    description = table.Column<string>(type: "text", nullable: true),
                    address_line1 = table.Column<string>(type: "text", nullable: false),
                    city = table.Column<string>(type: "text", nullable: false),
                    state = table.Column<string>(type: "text", nullable: false),
                    postal_code = table.Column<string>(type: "text", nullable: false),
                    status = table.Column<string>(type: "text", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_organizations", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "queue_events",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    zone_id = table.Column<Guid>(type: "uuid", nullable: true),
                    start_time = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    end_time = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    window_seconds = table.Column<int>(type: "integer", nullable: false),
                    status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "live")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_queue_events", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "SystemLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Timestamp = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    Level = table.Column<string>(type: "text", nullable: false),
                    Message = table.Column<string>(type: "text", nullable: false),
                    Component = table.Column<string>(type: "text", nullable: false),
                    SourceIp = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SystemLogs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "SystemRules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    RuleKey = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    IsEnabled = table.Column<bool>(type: "boolean", nullable: false),
                    Value = table.Column<string>(type: "text", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SystemRules", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    phone = table.Column<string>(type: "text", nullable: false),
                    password_hash = table.Column<string>(type: "text", nullable: false),
                    full_name = table.Column<string>(type: "text", nullable: false),
                    auth_provider = table.Column<string>(type: "text", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_users", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "vehicles",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    fleet_owner_id = table.Column<Guid>(type: "uuid", nullable: false),
                    current_driver_id = table.Column<Guid>(type: "uuid", nullable: true),
                    registration_number = table.Column<string>(type: "text", nullable: false),
                    vehicle_type = table.Column<string>(type: "text", nullable: false),
                    capacity_tons = table.Column<decimal>(type: "numeric", nullable: true),
                    max_load_weight_kg = table.Column<decimal>(type: "numeric", nullable: true),
                    status = table.Column<string>(type: "text", nullable: false),
                    availability_status = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_vehicles", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "shipments",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    shipment_number = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    sender_organization_id = table.Column<Guid>(type: "uuid", nullable: false),
                    receiver_organization_id = table.Column<Guid>(type: "uuid", nullable: false),
                    created_by_user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    pickup_address_id = table.Column<Guid>(type: "uuid", nullable: false),
                    drop_address_id = table.Column<Guid>(type: "uuid", nullable: false),
                    cargo_type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    cargo_description = table.Column<string>(type: "text", nullable: false),
                    cargo_weight_kg = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    cargo_volume_cubic_meters = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: true),
                    package_count = table.Column<int>(type: "integer", nullable: true),
                    requires_refrigeration = table.Column<bool>(type: "boolean", nullable: false),
                    requires_insurance = table.Column<bool>(type: "boolean", nullable: false),
                    special_handling_instructions = table.Column<string>(type: "text", nullable: true),
                    preferred_pickup_date = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    preferred_delivery_date = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    is_urgent = table.Column<bool>(type: "boolean", nullable: false),
                    agreed_price = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: true),
                    currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false),
                    price_per_unit = table.Column<string>(type: "text", nullable: true),
                    loading_charges = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    unloading_charges = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    other_charges = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    total_estimated_price = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    approved_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    rejection_reason = table.Column<string>(type: "text", nullable: true),
                    status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_shipments", x => x.id);
                    table.ForeignKey(
                        name: "fk_shipment_drop_address",
                        column: x => x.drop_address_id,
                        principalTable: "addresses",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_shipment_pickup_address",
                        column: x => x.pickup_address_id,
                        principalTable: "addresses",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "shipment_queue",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    shipment_id = table.Column<Guid>(type: "uuid", nullable: false),
                    zone_id = table.Column<Guid>(type: "uuid", nullable: true),
                    required_vehicle_type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false, defaultValue: "waiting"),
                    current_driver_id = table.Column<Guid>(type: "uuid", nullable: true),
                    offer_expires_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_shipment_queue", x => x.id);
                    table.ForeignKey(
                        name: "FK_shipment_queue_shipments_shipment_id",
                        column: x => x.shipment_id,
                        principalTable: "shipments",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "trips",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    trip_number = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    shipment_id = table.Column<Guid>(type: "uuid", nullable: false),
                    vehicle_id = table.Column<Guid>(type: "uuid", nullable: false),
                    driver_id = table.Column<Guid>(type: "uuid", nullable: false),
                    assigned_union_id = table.Column<Guid>(type: "uuid", nullable: true),
                    assigned_fleet_owner_id = table.Column<Guid>(type: "uuid", nullable: false),
                    assigned_by = table.Column<Guid>(type: "uuid", nullable: true),
                    assigned_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    planned_start_time = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    planned_end_time = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    estimated_distance_km = table.Column<decimal>(type: "numeric(10,2)", nullable: true),
                    estimated_duration_hours = table.Column<decimal>(type: "numeric(5,2)", nullable: true),
                    actual_start_time = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    actual_end_time = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    actual_distance_km = table.Column<decimal>(type: "numeric(10,2)", nullable: true),
                    current_status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false, defaultValue: "created"),
                    current_latitude = table.Column<decimal>(type: "numeric(10,8)", nullable: true),
                    current_longitude = table.Column<decimal>(type: "numeric(11,8)", nullable: true),
                    last_location_update_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    delivered_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    delivered_to_name = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    delivered_to_phone = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    proof_of_delivery_url = table.Column<string>(type: "text", nullable: true),
                    delivery_notes = table.Column<string>(type: "text", nullable: true),
                    sender_rating = table.Column<int>(type: "integer", nullable: true),
                    sender_feedback = table.Column<string>(type: "text", nullable: true),
                    receiver_rating = table.Column<int>(type: "integer", nullable: true),
                    receiver_feedback = table.Column<string>(type: "text", nullable: true),
                    driver_payment_amount = table.Column<decimal>(type: "numeric(10,2)", nullable: true),
                    driver_payment_status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "pending"),
                    driver_paid_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    has_issues = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    issue_description = table.Column<string>(type: "text", nullable: true),
                    delay_reason = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    updated_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    completed_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_trips", x => x.id);
                    table.ForeignKey(
                        name: "FK_trips_shipments_shipment_id",
                        column: x => x.shipment_id,
                        principalTable: "shipments",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "driver_queue_entries",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    queue_event_id = table.Column<Guid>(type: "uuid", nullable: false),
                    driver_id = table.Column<Guid>(type: "uuid", nullable: false),
                    position = table.Column<int>(type: "integer", nullable: false),
                    claim_window_start = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    claim_window_end = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    has_claimed = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    current_offered_shipment_queue_id = table.Column<Guid>(type: "uuid", nullable: true),
                    offer_status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "idle")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_driver_queue_entries", x => x.id);
                    table.ForeignKey(
                        name: "FK_driver_queue_entries_shipment_queue_current_offered_shipmen~",
                        column: x => x.current_offered_shipment_queue_id,
                        principalTable: "shipment_queue",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "shipment_queue_assignments",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    queue_event_id = table.Column<Guid>(type: "uuid", nullable: false),
                    shipment_queue_id = table.Column<Guid>(type: "uuid", nullable: false),
                    driver_id = table.Column<Guid>(type: "uuid", nullable: false),
                    driver_position = table.Column<int>(type: "integer", nullable: false),
                    offered_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    expires_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    outcome = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "pending")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_shipment_queue_assignments", x => x.id);
                    table.ForeignKey(
                        name: "FK_shipment_queue_assignments_queue_events_queue_event_id",
                        column: x => x.queue_event_id,
                        principalTable: "queue_events",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_shipment_queue_assignments_shipment_queue_shipment_queue_id",
                        column: x => x.shipment_queue_id,
                        principalTable: "shipment_queue",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_driver_queue_entries_current_offered_shipment_queue_id",
                table: "driver_queue_entries",
                column: "current_offered_shipment_queue_id");

            migrationBuilder.CreateIndex(
                name: "IX_shipment_queue_shipment_id",
                table: "shipment_queue",
                column: "shipment_id");

            migrationBuilder.CreateIndex(
                name: "IX_shipment_queue_assignments_driver_id",
                table: "shipment_queue_assignments",
                column: "driver_id");

            migrationBuilder.CreateIndex(
                name: "IX_shipment_queue_assignments_queue_event_id",
                table: "shipment_queue_assignments",
                column: "queue_event_id");

            migrationBuilder.CreateIndex(
                name: "IX_shipment_queue_assignments_shipment_queue_id",
                table: "shipment_queue_assignments",
                column: "shipment_queue_id");

            migrationBuilder.CreateIndex(
                name: "IX_shipments_drop_address_id",
                table: "shipments",
                column: "drop_address_id");

            migrationBuilder.CreateIndex(
                name: "IX_shipments_pickup_address_id",
                table: "shipments",
                column: "pickup_address_id");

            migrationBuilder.CreateIndex(
                name: "IX_shipments_shipment_number",
                table: "shipments",
                column: "shipment_number",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_trips_assigned_union_id",
                table: "trips",
                column: "assigned_union_id");

            migrationBuilder.CreateIndex(
                name: "IX_trips_current_status",
                table: "trips",
                column: "current_status");

            migrationBuilder.CreateIndex(
                name: "IX_trips_driver_id",
                table: "trips",
                column: "driver_id");

            migrationBuilder.CreateIndex(
                name: "IX_trips_shipment_id",
                table: "trips",
                column: "shipment_id");

            migrationBuilder.CreateIndex(
                name: "IX_trips_trip_number",
                table: "trips",
                column: "trip_number",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "driver_queue_entries");

            migrationBuilder.DropTable(
                name: "drivers");

            migrationBuilder.DropTable(
                name: "fleet_owners");

            migrationBuilder.DropTable(
                name: "organizations");

            migrationBuilder.DropTable(
                name: "shipment_queue_assignments");

            migrationBuilder.DropTable(
                name: "SystemLogs");

            migrationBuilder.DropTable(
                name: "SystemRules");

            migrationBuilder.DropTable(
                name: "trips");

            migrationBuilder.DropTable(
                name: "users");

            migrationBuilder.DropTable(
                name: "vehicles");

            migrationBuilder.DropTable(
                name: "queue_events");

            migrationBuilder.DropTable(
                name: "shipment_queue");

            migrationBuilder.DropTable(
                name: "shipments");

            migrationBuilder.DropTable(
                name: "addresses");
        }
    }
}
