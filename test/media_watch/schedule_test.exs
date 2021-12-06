defmodule MediaWatch.ScheduleTest do
  use ExUnit.Case
  import Crontab.CronExpression
  alias MediaWatch.Schedule

  @every_weekday_at_8 ~e[0 8 * * MON-FRI]
  @every_sunday_at_8 ~e[0 8 * * SUN]
  @friday ~D[2021-12-03]
  @saturday ~D[2021-12-04]
  @sunday ~D[2021-12-05]
  @previous_sunday ~D[2021-11-28]
  @monday ~D[2021-12-06]
  @tuesday ~D[2021-12-07]
  @wednesday ~D[2021-12-08]
  @seven ~T[07:00:00]
  @eigth ~T[08:00:00]
  @nine ~T[09:00:00]
  @nine_evening ~T[21:00:00]
  @friday_at_8 DateTime.new!(@friday, @eigth)
  @friday_at_9 DateTime.new!(@friday, @nine)
  @saturday_at_9 DateTime.new!(@saturday, @nine)
  @previous_sunday_at_8 DateTime.new!(@previous_sunday, @eigth)
  @sunday_at_7 DateTime.new!(@sunday, @seven)
  @sunday_at_8 DateTime.new!(@sunday, @eigth)
  @sunday_at_9 DateTime.new!(@sunday, @nine)
  @monday_at_7 DateTime.new!(@monday, @seven)
  @tuesday_at_21 DateTime.new!(@tuesday, @nine_evening)
  @tuesday_at_9 DateTime.new!(@tuesday, @nine)
  @tuesday_at_8 DateTime.new!(@tuesday, @eigth)
  @wednesday_at_7 DateTime.new!(@wednesday, @seven)
  @timezone_minus "Etc/GMT-10"
  @timezone_plus "Etc/GMT+10"

  defp assert_dates_equal(dt1, dt2), do: DateTime.compare(dt1, dt2) == :eq

  describe "get_airing_time/2" do
    test "does not work with NaiveDateTime" do
      assert_raise FunctionClauseError, fn ->
        Schedule.get_airing_time(@every_weekday_at_8, NaiveDateTime.utc_now())
      end
    end

    for tz <- [@timezone_minus, @timezone_plus] do
      test "accounts for the time zone #{tz}" do
        tz = unquote(tz)
        tuesday_at_9 = DateTime.new!(@tuesday, @nine, tz)
        tuesday_at_8 = DateTime.new!(@tuesday, @eigth, tz)
        tuesday_at_7 = DateTime.new!(@tuesday, @seven, tz)
        monday_at_8 = DateTime.new!(@monday, @eigth, tz)

        assert_dates_equal(
          Schedule.get_airing_time(@every_weekday_at_8, tuesday_at_7),
          monday_at_8
        )

        assert_dates_equal(
          Schedule.get_airing_time(@every_weekday_at_8, tuesday_at_9),
          tuesday_at_8
        )
      end
    end
  end

  describe "get_airing_time/2 for a weekday schedule" do
    test "should return tuesday for the whole period from tuesday at 8 to wednesday at 8" do
      assert_dates_equal(
        Schedule.get_airing_time(@every_weekday_at_8, @tuesday_at_9),
        @tuesday_at_8
      )

      assert_dates_equal(
        Schedule.get_airing_time(@every_weekday_at_8, @tuesday_at_21),
        @tuesday_at_8
      )

      assert_dates_equal(
        Schedule.get_airing_time(@every_weekday_at_8, @wednesday_at_7),
        @tuesday_at_8
      )
    end

    test "should return friday for the whole period from friday at 8 to monday at 8" do
      assert_dates_equal(
        Schedule.get_airing_time(@every_weekday_at_8, @friday_at_9),
        @friday_at_8
      )

      assert_dates_equal(
        Schedule.get_airing_time(@every_weekday_at_8, @saturday_at_9),
        @friday_at_8
      )

      assert_dates_equal(
        Schedule.get_airing_time(@every_weekday_at_8, @sunday_at_9),
        @friday_at_8
      )

      assert_dates_equal(
        Schedule.get_airing_time(@every_weekday_at_8, @monday_at_7),
        @friday_at_8
      )
    end
  end

  describe "get_airing_time/2 for a weekend schedule" do
    test "should return sunday for the whole period from sunday at 8" do
      assert_dates_equal(Schedule.get_airing_time(@every_sunday_at_8, @sunday_at_9), @sunday_at_8)
      assert_dates_equal(Schedule.get_airing_time(@every_sunday_at_8, @monday_at_7), @sunday_at_8)

      assert_dates_equal(
        Schedule.get_airing_time(@every_sunday_at_8, @wednesday_at_7),
        @sunday_at_8
      )
    end

    test "should return previous sunday for the whole period before sunday at 8" do
      assert_dates_equal(
        Schedule.get_airing_time(@every_sunday_at_8, @sunday_at_7),
        @previous_sunday_at_8
      )

      assert_dates_equal(
        Schedule.get_airing_time(@every_sunday_at_8, @saturday_at_9),
        @previous_sunday_at_8
      )

      assert_dates_equal(
        Schedule.get_airing_time(@every_sunday_at_8, @friday_at_8),
        @previous_sunday_at_8
      )
    end
  end
end
