/// Internal entry context on /weekly-planner; no additional public route.
enum PlanningView { today, tomorrow, week, undated }

/// Explicit navigation intent; never a public query parameter.
class PlanningRequest {
  PlanningRequest(this.view);
  final PlanningView view;
}
