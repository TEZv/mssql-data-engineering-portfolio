# Project 2 — Media Performance Mart Maintenance & Evolution

## Goal

Maintain and evolve an existing daily media reporting mart while source facts arrive late, are corrected, and must remain consistent for Power BI. The scenario reflects real analytical problem types while all fixtures are synthetic.

## Engineering focus

- Stable grain: one row per video, metric date and traffic source.
- Transactional upsert for late-arriving and corrected facts.
- A run audit with inserted/updated counts.
- Weighted retention (`sum(percentage * views) / sum(views)`), never a simple average.
- Window functions for rolling performance.
- Inline table-valued function for reusable, optimizer-friendly aggregation.
- Data-quality and retry assertions.

## Maintenance evidence

This is the first upkeep-focused project: correction handling, audit/reconciliation, retention of pipeline history, index care and an incident runbook are the primary acceptance criteria, while new T-SQL objects demonstrate continued database development.

## Model

```text
ref.Channel -> ref.Video -> mart.DailyVideoMetric -> mart.vw_VideoPerformance
                                 |
                                 +-> audit.PipelineRun
                                 +-> mart.fn_ChannelRetention(...)
```
