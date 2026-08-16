using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MedGuard.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddMedicationExpirationDate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateOnly>(
                name: "ExpirationDate",
                table: "Medications",
                type: "date",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ExpirationDate",
                table: "Medications");
        }
    }
}
