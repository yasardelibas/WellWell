using System.Net;
using MedGuard.Contracts.Caregivers;
using MedGuard.Contracts.Medications;
using Xunit;

namespace MedGuard.IntegrationTests;

/// <summary>caregiver invite → permission check</summary>
public sealed class CaregiverFlowTests : IClassFixture<MedGuardApiFactory>
{
    private readonly MedGuardApiFactory _factory;

    public CaregiverFlowTests(MedGuardApiFactory factory) => _factory = factory;

    [Fact]
    public async Task Invitation_ShouldGrantNothing_UntilTheOwnerApprovesThePermissions()
    {
        var owner = await _factory.RegisterAsync();
        await AddMedicationAsync(owner);

        var caregiverEmail = $"caregiver-{Guid.NewGuid():N}@example.com";
        var invitation = await InviteAsync(owner, caregiverEmail, "VIEW_MEDICATION_LIST", "VIEW_ADHERENCE");

        Assert.Equal("Invited", invitation.Caregiver.Status);
        Assert.Empty(invitation.Caregiver.Permissions);

        var caregiver = await _factory.RegisterAsync(caregiverEmail);
        var accepted = await AcceptAsync(caregiver, invitation);

        Assert.Equal("Accepted", accepted.Status);
        Assert.Empty(accepted.Permissions);

        // Acceptance alone must not open any data.
        var beforeApproval = await caregiver.Client.GetAsync(
            $"/api/caregivers/shared-with-me/{invitation.Caregiver.Id}/medications");
        Assert.Equal(HttpStatusCode.Forbidden, beforeApproval.StatusCode);

        var approvedResponse = await owner.Client.PutJsonAsync(
            $"/api/caregivers/{invitation.Caregiver.Id}/permissions",
            new UpdateCaregiverPermissionsRequest(new[] { "VIEW_MEDICATION_LIST" }));

        Assert.Equal(HttpStatusCode.OK, approvedResponse.StatusCode);
        var approved = await approvedResponse.ReadAsync<CaregiverResponse>();
        Assert.Equal("Active", approved.Status);
        Assert.Equal(new[] { "VIEW_MEDICATION_LIST" }, approved.Permissions);

        var medications = await caregiver.Client.GetAsync<List<MedicationResponse>>(
            $"/api/caregivers/shared-with-me/{invitation.Caregiver.Id}/medications");
        Assert.Single(medications);

        // Only the approved capability is available.
        var adherence = await caregiver.Client.GetAsync(
            $"/api/caregivers/shared-with-me/{invitation.Caregiver.Id}/adherence");
        Assert.Equal(HttpStatusCode.Forbidden, adherence.StatusCode);
    }

    [Fact]
    public async Task SharedWithMe_ShouldIdentifyWhichOwnerEachRelationshipBelongsTo()
    {
        var firstOwner = await _factory.RegisterAsync();
        var secondOwner = await _factory.RegisterAsync();
        var caregiverEmail = $"caregiver-{Guid.NewGuid():N}@example.com";

        var caregiver = await _factory.RegisterAsync(caregiverEmail);
        var firstInvitation = await InviteAsync(firstOwner, caregiverEmail, "VIEW_MEDICATION_LIST");
        var secondInvitation = await InviteAsync(secondOwner, caregiverEmail, "VIEW_MEDICATION_LIST");
        await AcceptAsync(caregiver, firstInvitation);
        await AcceptAsync(caregiver, secondInvitation);

        // A relationship only becomes "Active" (and thus visible to the caregiver) once the owner approves.
        await firstOwner.Client.PutJsonAsync(
            $"/api/caregivers/{firstInvitation.Caregiver.Id}/permissions",
            new UpdateCaregiverPermissionsRequest(new[] { "VIEW_MEDICATION_LIST" }));
        await secondOwner.Client.PutJsonAsync(
            $"/api/caregivers/{secondInvitation.Caregiver.Id}/permissions",
            new UpdateCaregiverPermissionsRequest(new[] { "VIEW_MEDICATION_LIST" }));

        var shared = await caregiver.Client.GetAsync<List<SharedWithMeResponse>>("/api/caregivers/shared-with-me");

        Assert.Equal(2, shared.Count);
        var ownerEmails = shared.Select(relationship => relationship.OwnerEmail).ToList();
        Assert.Contains(firstOwner.Email, ownerEmails);
        Assert.Contains(secondOwner.Email, ownerEmails);
        // A stable identity per relationship is the whole point — they must not be interchangeable.
        Assert.NotEqual(shared[0].OwnerEmail, shared[1].OwnerEmail);
    }

    [Fact]
    public async Task Revocation_ShouldCloseAccessImmediately()
    {
        var owner = await _factory.RegisterAsync();
        await AddMedicationAsync(owner);

        var caregiverEmail = $"caregiver-{Guid.NewGuid():N}@example.com";
        var invitation = await InviteAsync(owner, caregiverEmail, "VIEW_MEDICATION_LIST");
        var caregiver = await _factory.RegisterAsync(caregiverEmail);

        await AcceptAsync(caregiver, invitation);
        await owner.Client.PutJsonAsync(
            $"/api/caregivers/{invitation.Caregiver.Id}/permissions",
            new UpdateCaregiverPermissionsRequest(new[] { "VIEW_MEDICATION_LIST" }));

        var granted = await caregiver.Client.GetAsync(
            $"/api/caregivers/shared-with-me/{invitation.Caregiver.Id}/medications");
        Assert.Equal(HttpStatusCode.OK, granted.StatusCode);

        var revoke = await owner.Client.DeleteAsync($"/api/caregivers/{invitation.Caregiver.Id}");
        Assert.Equal(HttpStatusCode.NoContent, revoke.StatusCode);

        var afterRevocation = await caregiver.Client.GetAsync(
            $"/api/caregivers/shared-with-me/{invitation.Caregiver.Id}/medications");
        Assert.Equal(HttpStatusCode.Forbidden, afterRevocation.StatusCode);

        Assert.Empty(await owner.Client.GetAsync<List<CaregiverResponse>>("/api/caregivers"));
    }

    [Fact]
    public async Task Acceptance_ShouldBeRefused_WhenTheInvitationBelongsToAnotherEmail()
    {
        var owner = await _factory.RegisterAsync();
        var invitation = await InviteAsync(owner, $"caregiver-{Guid.NewGuid():N}@example.com", "VIEW_ADHERENCE");

        var someoneElse = await _factory.RegisterAsync();
        var response = await someoneElse.Client.PostJsonAsync(
            $"/api/caregivers/invitations/{invitation.Caregiver.Id}/accept",
            new AcceptCaregiverInvitationRequest(invitation.InvitationToken!));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Acceptance_ShouldBeRefused_WhenTheTokenIsWrong()
    {
        var owner = await _factory.RegisterAsync();
        var caregiverEmail = $"caregiver-{Guid.NewGuid():N}@example.com";
        var invitation = await InviteAsync(owner, caregiverEmail, "VIEW_ADHERENCE");
        var caregiver = await _factory.RegisterAsync(caregiverEmail);

        var response = await caregiver.Client.PostJsonAsync(
            $"/api/caregivers/invitations/{invitation.Caregiver.Id}/accept",
            new AcceptCaregiverInvitationRequest("not-the-invitation-token"));

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Invite_ShouldRejectAnUnknownPermissionName()
    {
        var owner = await _factory.RegisterAsync();

        var response = await owner.Client.PostJsonAsync(
            "/api/caregivers/invitations",
            new InviteCaregiverRequest("someone@example.com", new[] { "VIEW_EVERYTHING" }));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Invite_ShouldRejectTheOwnersOwnEmail()
    {
        var owner = await _factory.RegisterAsync();

        var response = await owner.Client.PostJsonAsync(
            "/api/caregivers/invitations",
            new InviteCaregiverRequest(owner.Email, new[] { "VIEW_ADHERENCE" }));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Permissions_ShouldNotBeChangeableByAnyoneButTheOwner()
    {
        var owner = await _factory.RegisterAsync();
        var caregiverEmail = $"caregiver-{Guid.NewGuid():N}@example.com";
        var invitation = await InviteAsync(owner, caregiverEmail, "VIEW_ADHERENCE");
        var caregiver = await _factory.RegisterAsync(caregiverEmail);
        await AcceptAsync(caregiver, invitation);

        var response = await caregiver.Client.PutJsonAsync(
            $"/api/caregivers/{invitation.Caregiver.Id}/permissions",
            new UpdateCaregiverPermissionsRequest(new[] { "VIEW_MEDICATION_LIST" }));

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    private static async Task<CaregiverInvitationResponse> InviteAsync(
        TestUser owner,
        string email,
        params string[] permissions)
    {
        var response = await owner.Client.PostJsonAsync(
            "/api/caregivers/invitations",
            new InviteCaregiverRequest(email, permissions));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var invitation = await response.ReadAsync<CaregiverInvitationResponse>();
        Assert.False(string.IsNullOrWhiteSpace(invitation.InvitationToken));

        return invitation;
    }

    private static async Task<CaregiverResponse> AcceptAsync(TestUser caregiver, CaregiverInvitationResponse invitation)
    {
        var response = await caregiver.Client.PostJsonAsync(
            $"/api/caregivers/invitations/{invitation.Caregiver.Id}/accept",
            new AcceptCaregiverInvitationRequest(invitation.InvitationToken!));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return await response.ReadAsync<CaregiverResponse>();
    }

    private static async Task AddMedicationAsync(TestUser owner)
    {
        var response = await owner.Client.PostJsonAsync(
            "/api/medications",
            new CreateMedicationRequest(
                "Advil",
                "Ibuprofen",
                new[] { new IngredientInput("Ibuprofen", 400m, "mg", null) },
                "Tablet",
                "400 mg",
                "Oral",
                "Take 1 tablet twice daily.",
                null));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }
}
