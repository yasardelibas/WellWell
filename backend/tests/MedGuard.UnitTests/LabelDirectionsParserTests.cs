using MedGuard.Application.Schedules;
using Xunit;

namespace MedGuard.UnitTests;

public sealed class LabelDirectionsParserTests
{
    [Theory]
    [InlineData("Take one tablet twice daily.", 2)]
    [InlineData("Take 1 tablet 3 times a day", 3)]
    [InlineData("Take one tablet once daily", 1)]
    [InlineData("Take 1 capsule every 8 hours", 3)]
    [InlineData("Take 1 tablet every 12 hours", 2)]
    public void Parse_ShouldReadDosingFrequency_FromCommonLabelWording(string directions, int expected) =>
        Assert.Equal(expected, LabelDirectionsParser.Parse(directions).TimesPerDay);

    [Fact]
    public void Parse_ShouldSuggestTwoTimes_ForTwiceDaily()
    {
        var suggestion = LabelDirectionsParser.Parse("Take 1 tablet twice daily with meals.");

        Assert.Equal(new[] { new TimeOnly(8, 0), new TimeOnly(20, 0) }, suggestion.SuggestedTimes);
        Assert.Equal("1 tablet", suggestion.DoseAmountText);
        Assert.Equal("Take 1 tablet twice daily with meals.", suggestion.LabelInstruction);
    }

    [Fact]
    public void Parse_ShouldSuggestBedtime_WhenLabelSaysAtBedtime()
    {
        var suggestion = LabelDirectionsParser.Parse("Take one tablet at bedtime.");

        Assert.Equal(new[] { new TimeOnly(22, 0) }, suggestion.SuggestedTimes);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("Store below 25 degrees.")]
    public void Parse_ShouldSuggestNothing_WhenFrequencyIsNotStated(string? directions)
    {
        var suggestion = LabelDirectionsParser.Parse(directions);

        Assert.Equal(0, suggestion.TimesPerDay);
        Assert.Empty(suggestion.SuggestedTimes);
    }

    [Fact]
    public void Parse_ShouldKeepLabelInstructionVerbatim()
    {
        const string directions = "Take 2 tablets three times daily after food.";

        var suggestion = LabelDirectionsParser.Parse(directions);

        Assert.Equal(directions, suggestion.LabelInstruction);
        Assert.Equal("2 tablets", suggestion.DoseAmountText);
        Assert.Equal(3, suggestion.SuggestedTimes.Count);
    }
}
