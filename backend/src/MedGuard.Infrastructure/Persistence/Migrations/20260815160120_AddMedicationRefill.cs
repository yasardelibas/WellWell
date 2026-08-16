using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MedGuard.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddMedicationRefill : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "RemainingQuantity",
                table: "Medications",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "RemainingUpdatedAt",
                table: "Medications",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RemainingQuantity",
                table: "Medications");

            migrationBuilder.DropColumn(
                name: "RemainingUpdatedAt",
                table: "Medications");
        }
    }
}
