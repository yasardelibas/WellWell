using System.Net;
using MedGuard.Contracts.Adherence;
using MedGuard.Contracts.Medications;
using MedGuard.Contracts.Scanning;
using MedGuard.Contracts.Schedules;
using Xunit;

namespace MedGuard.IntegrationTests;

/// <summary>schedule → dose event</summary>
public sealed class ScheduleAdherenceFlowTests : IClassFixture<MedGuardApiFactory>
{
    private readonly MedGuardApiFactory _factory;

    public ScheduleAdherenceFlowTests(MedGuardApiFactory factory) => _factory = factory;

    [Fact]
    public async Task Suggestion_ShouldDeriveTimesFromTheLabel_WithoutCreatingAnything()
    {
        var user = await _factory.RegisterAsync();
        var medication = await CreateMedicationAsync(user);

        var suggestion = await user.Client.GetAsync<ScheduleSuggestionResponse>(
            $"/api/schedules/suggestion?medicationId={medication.Id}");

        Assert.Equal(2, suggestion.TimesPerDay);
        Assert.Equal(new[] { "08:00", "20:00" }, suggestion.SuggestedTimes);
        Assert.True(suggestion.RequiresUserConfirmation);

        var schedules = await user.Client.GetAsync<List<ScheduleResponse>>("/api/schedules");
        Assert.Empty(schedules);
    }

    [Fact]
    public async Task CreateSchedule_ShouldBeRefused_WhenTheUserHasNotConfirmedTheTimes()
    {
        var user = await _factory.RegisterAsync();
        var medication = await CreateMedicationAsync(user);

        var response = await user.Client.PostJsonAsync(
            "/api/schedules",
            new CreateScheduleRequest(medication.Id, new[] { "08:00" }, null, "1 tablet", UserConfirmed: false));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Empty(await user.Client.GetAsync<List<ScheduleResponse>>("/api/schedules"));
    }

    [Fact]
    public async Task ConfirmedSchedule_ShouldProduceTodaysDoseEvents()
    {
        var user = await _factory.RegisterAsync();
        var medication = await CreateMedicationAsync(user);

        var schedules = await CreateSchedulesAsync(user, medication.Id, "08:00", "20:00");

        Assert.Equal(2, schedules.Count);
        Assert.All(schedules, schedule => Assert.True(schedule.UserConfirmed && schedule.IsActive));

        var today = await user.Client.GetAsync<TodayScheduleResponse>("/api/adherence/today");

        Assert.Equal(2, today.TotalCount);
        Assert.Equal(new[] { "08:00", "20:00" }, today.Doses.Select(dose => dose.ScheduledTime));
        Assert.All(today.Doses, dose => Assert.Equal(medication.Id, dose.MedicationId));
    }

    [Fact]
    public async Task MarkingADose_ShouldRecordItInTodaysPlanAndInHistory()
    {
        var user = await _factory.RegisterAsync();
        var medication = await CreateMedicationAsync(user);
        await CreateSchedulesAsync(user, medication.Id, "08:00", "20:00");

        var today = await user.Client.GetAsync<TodayScheduleResponse>("/api/adherence/today");
        var first = today.Doses.First();
        var second = today.Doses.Last();

        var takenResponse = await user.Client.PostJsonAsync($"/api/doses/{first.Id}/taken", new { });
        var taken = await takenResponse.ReadAsync<DoseResponse>();

        var skippedResponse = await user.Client.PostJsonAsync($"/api/doses/{second.Id}/skip", new { });
        var skipped = await skippedResponse.ReadAsync<DoseResponse>();

        Assert.Equal("taken", taken.Status);
        Assert.Equal("Taken", taken.StatusLabel);
        Assert.NotNull(taken.CompletedAt);
        Assert.Equal("skipped", skipped.Status);

        var refreshed = await user.Client.GetAsync<TodayScheduleResponse>("/api/adherence/today");
        Assert.Equal(1, refreshed.CompletedCount);
        Assert.Equal("1 of 2 scheduled doses completed.", refreshed.ProgressLabel);

        var history = await user.Client.GetAsync<AdherenceHistoryResponse>("/api/adherence/history");
        Assert.Equal(1, history.TakenCount);
        Assert.Equal(1, history.SkippedCount);
        Assert.Contains(history.Days, day => day.Doses.Any(dose => dose.Id == first.Id));
    }

    [Fact]
    public async Task Snoozing_ShouldMoveTheReminderWithoutCompletingTheDose()
    {
        var user = await _factory.RegisterAsync();
        var medication = await CreateMedicationAsync(user);
        await CreateSchedulesAsync(user, medication.Id, "08:00");

        var today = await user.Client.GetAsync<TodayScheduleResponse>("/api/adherence/today");
        var dose = today.Doses.Single();

        var response = await user.Client.PostJsonAsync($"/api/doses/{dose.Id}/snooze", new SnoozeDoseRequest(30));
        var snoozed = await response.ReadAsync<DoseResponse>();

        Assert.Equal("snoozed", snoozed.Status);
        Assert.NotNull(snoozed.SnoozedUntil);
        Assert.Null(snoozed.CompletedAt);
    }

    [Fact]
    public async Task ResubmittingTheTimes_ShouldDeactivateTheRemovedReminders()
    {
        var user = await _factory.RegisterAsync();
        var medication = await CreateMedicationAsync(user);
        await CreateSchedulesAsync(user, medication.Id, "08:00", "20:00");

        await CreateSchedulesAsync(user, medication.Id, "08:00");

        var schedules = await user.Client.GetAsync<List<ScheduleResponse>>("/api/schedules");

        Assert.Equal(2, schedules.Count);
        Assert.True(schedules.Single(schedule => schedule.Time == "08:00").IsActive);
        Assert.False(schedules.Single(schedule => schedule.Time == "20:00").IsActive);
    }

    [Fact]
    public async Task DeletingASchedule_ShouldStopProducingDoses()
    {
        var user = await _factory.RegisterAsync();
        var medication = await CreateMedicationAsync(user);
        var schedules = await CreateSchedulesAsync(user, medication.Id, "08:00");

        var response = await user.Client.DeleteAsync($"/api/schedules/{schedules.Single().Id}");
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        var today = await user.Client.GetAsync<TodayScheduleResponse>("/api/adherence/today");
        Assert.Equal(0, today.TotalCount);

        var remaining = await user.Client.GetAsync<List<ScheduleResponse>>("/api/schedules");
        Assert.False(remaining.Single().IsActive);
    }

    [Fact]
    public async Task CreateSchedule_ShouldRejectAMedicationOwnedByAnotherAccount()
    {
        var owner = await _factory.RegisterAsync();
        var stranger = await _factory.RegisterAsync();
        var medication = await CreateMedicationAsync(owner);

        var response = await stranger.Client.PostJsonAsync(
            "/api/schedules",
            new CreateScheduleRequest(medication.Id, new[] { "08:00" }, null, null, UserConfirmed: true));

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task CreateSchedule_ShouldRejectAnUnparsableTime()
    {
        var user = await _factory.RegisterAsync();
        var medication = await CreateMedicationAsync(user);

        var response = await user.Client.PostJsonAsync(
            "/api/schedules",
            new CreateScheduleRequest(medication.Id, new[] { "quarter past eight" }, null, null, UserConfirmed: true));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private static async Task<MedicationResponse> CreateMedicationAsync(TestUser user)
    {
        var response = await user.Client.PostJsonAsync(
            "/api/medications",
            new CreateMedicationRequest(
                "Glucophage",
                "Metformin Hydrochloride",
                new[] { new IngredientInput("Metformin Hydrochloride", 500m, "mg", null) },
                "Tablet",
                "500 mg",
                "Oral",
                "Take 1 tablet twice daily.",
                null));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return await response.ReadAsync<MedicationResponse>();
    }

    private static async Task<List<ScheduleResponse>> CreateSchedulesAsync(
        TestUser user,
        Guid medicationId,
        params string[] times)
    {
        var response = await user.Client.PostJsonAsync(
            "/api/schedules",
            new CreateScheduleRequest(medicationId, times, "1 tablet, twice daily", "1 tablet", UserConfirmed: true));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return await response.ReadAsync<List<ScheduleResponse>>();
    }
}
