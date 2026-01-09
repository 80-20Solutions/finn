# Deployment Checklist - Category-Only Budget System

## Overview

This checklist ensures safe deployment of the category-only budget system to production.

**Branch:** `002-category-only-budgets`
**Target:** Production environment
**Impact:** High - Affects all users with budgets
**Rollback:** Available (see Migration Testing Guide)

---

## Phase 1: Pre-Deployment Preparation

### 1.1 Code Review
- [ ] All commits reviewed and approved
- [ ] No merge conflicts with main branch
- [ ] Code follows project conventions
- [ ] No commented-out code or debug statements
- [ ] All TODOs addressed or documented

### 1.2 Testing Validation
- [ ] All migrations tested on staging database
- [ ] Migration testing guide followed completely
- [ ] All edge cases tested
- [ ] UI widgets tested in isolation
- [ ] Provider state management verified
- [ ] No console errors in dev/staging

### 1.3 Documentation
- [ ] PROGRESS.md updated to 100%
- [ ] Migration testing guide complete
- [ ] Deployment checklist finalized
- [ ] User-facing documentation prepared
- [ ] API changes documented (if any)

### 1.4 Database Backup
- [ ] Full production database backup created
- [ ] Backup verified and downloadable
- [ ] Backup storage location documented
- [ ] Restore procedure tested on staging

### 1.5 Rollback Plan
- [ ] Rollback script tested on staging
- [ ] Rollback procedure documented
- [ ] Team trained on rollback process
- [ ] Rollback decision criteria defined

---

## Phase 2: Staging Deployment

### 2.1 Deploy to Staging
- [ ] Merge branch to staging environment
- [ ] Run migrations on staging database
- [ ] Deploy application code to staging
- [ ] Verify staging deployment successful

### 2.2 Staging Validation
- [ ] All migrations applied successfully
- [ ] Views return correct data
- [ ] RPC functions work correctly
- [ ] Triggers functioning properly
- [ ] UI displays correctly
- [ ] No errors in staging logs

### 2.3 Integration Testing
- [ ] Create new category budget - works
- [ ] Update existing category budget - works
- [ ] Delete category budget - works
- [ ] View calculated totals - correct
- [ ] Virtual group category displays - correct
- [ ] Altro category auto-created - works
- [ ] Uncategorized expenses auto-assigned - works
- [ ] System category badge displays - correct
- [ ] Onboarding widget displays - correct

### 2.4 Performance Testing
- [ ] Page load times acceptable (<2s)
- [ ] Database queries performant (<100ms)
- [ ] No memory leaks detected
- [ ] No excessive network requests

### 2.5 Staging Sign-Off
- [ ] QA team approval
- [ ] Product owner approval
- [ ] Technical lead approval
- [ ] No critical issues found

---

## Phase 3: Production Deployment Strategy

### 3.1 Choose Deployment Method

**Option A: Full Deployment** (Recommended if low traffic)
- Deploy to all users at once
- Fastest rollout
- Higher risk

**Option B: Gradual Rollout** (Recommended if high traffic)
- Deploy to 10% users first
- Monitor for 24 hours
- Increase to 50%, then 100%
- Lower risk, slower

**Option C: Feature Flag** (Most cautious)
- Deploy code with feature disabled
- Enable for test users
- Gradually enable for all users
- Safest, most complex

**Chosen Method:** [ Option A / B / C ]

### 3.2 Deployment Window
- [ ] Deployment window scheduled
- [ ] Low-traffic period selected
- [ ] Team availability confirmed
- [ ] Stakeholders notified

---

## Phase 4: Production Deployment

### 4.1 Database Migration
- [ ] Create production database backup
- [ ] Backup verified and stored safely
- [ ] Run migration 052 (deprecate manual budgets)
- [ ] Verify migration 052 successful
- [ ] Run migration 053 (system category flag)
- [ ] Verify migration 053 successful
- [ ] Run migration 054 (ensure_altro RPC)
- [ ] Verify migration 054 successful
- [ ] Run migration 055 (budget total views)
- [ ] Verify migration 055 successful
- [ ] Run migration 056 (data migration)
- [ ] Verify migration 056 successful
- [ ] Run migration 057 (auto-assign trigger)
- [ ] Verify migration 057 successful

### 4.2 Data Validation
- [ ] All manual budgets marked deprecated
- [ ] Category budgets created from manual budgets
- [ ] System categories marked correctly
- [ ] No uncategorized expenses remain
- [ ] Views return expected data
- [ ] RPC functions working
- [ ] Triggers functioning

### 4.3 Application Deployment
- [ ] Build application (flutter build)
- [ ] Run tests (flutter test)
- [ ] Deploy to production servers
- [ ] Verify deployment successful
- [ ] Application starts without errors

### 4.4 Immediate Validation
- [ ] Application accessible
- [ ] No critical errors in logs
- [ ] Database connections healthy
- [ ] API endpoints responding
- [ ] Users can log in
- [ ] Budgets display correctly

---

## Phase 5: Post-Deployment Monitoring

### 5.1 First Hour Monitoring
- [ ] Monitor error logs continuously
- [ ] Watch database performance
- [ ] Check API response times
- [ ] Monitor user reports
- [ ] Verify key workflows work

### 5.2 First 24 Hours
- [ ] Error rate within normal range (<1%)
- [ ] No database performance issues
- [ ] No user complaints about budgets
- [ ] All features functioning correctly
- [ ] No rollback triggers activated

### 5.3 Metrics to Track
- [ ] Error rate (target: <1%)
- [ ] API response times (target: <500ms)
- [ ] Database query times (target: <100ms)
- [ ] User engagement (should be normal)
- [ ] Support tickets (should not spike)

### 5.4 Key User Flows to Monitor
- [ ] Create new budget
- [ ] Edit existing budget
- [ ] View budget dashboard
- [ ] Add expense to budget
- [ ] View calculated totals

---

## Phase 6: Gradual Rollout (if applicable)

### 6.1 10% Rollout
- [ ] Enable for 10% of users
- [ ] Monitor for 24 hours
- [ ] No critical issues found
- [ ] User feedback positive
- [ ] Ready to proceed

### 6.2 50% Rollout
- [ ] Enable for 50% of users
- [ ] Monitor for 24 hours
- [ ] No critical issues found
- [ ] Performance acceptable
- [ ] Ready to proceed

### 6.3 100% Rollout
- [ ] Enable for all users
- [ ] Monitor for 48 hours
- [ ] No critical issues found
- [ ] Success criteria met
- [ ] Rollout complete

---

## Phase 7: Post-Deployment Tasks

### 7.1 Documentation Updates
- [ ] Update user documentation
- [ ] Update technical documentation
- [ ] Document any issues found
- [ ] Document lessons learned
- [ ] Update PROGRESS.md to 100%

### 7.2 Communication
- [ ] Announce deployment to team
- [ ] Notify stakeholders of success
- [ ] Send user communication (if needed)
- [ ] Update status page

### 7.3 Cleanup (After 30 Days)
- [ ] Remove deprecated code paths
- [ ] Delete old migration backups
- [ ] Archive deployment documentation
- [ ] Remove feature flags (if used)
- [ ] Update codebase version

### 7.4 Retrospective
- [ ] Schedule team retrospective
- [ ] Discuss what went well
- [ ] Discuss what could improve
- [ ] Document action items
- [ ] Update deployment process

---

## Rollback Decision Criteria

Rollback IMMEDIATELY if:
- ✗ Error rate exceeds 5%
- ✗ Database corruption detected
- ✗ Data loss occurs
- ✗ Critical feature completely broken
- ✗ Security vulnerability discovered

Rollback within 1 hour if:
- ✗ Error rate exceeds 2% for >30 minutes
- ✗ Major feature broken for many users
- ✗ Performance degradation >50%
- ✗ Multiple critical bugs reported

Consider rollback if:
- ⚠ Error rate exceeds 1% for >2 hours
- ⚠ Minor features broken
- ⚠ Performance degradation 25-50%
- ⚠ Negative user feedback spike

---

## Rollback Procedure

### 1. Immediate Actions
- [ ] Announce rollback decision
- [ ] Stop new deployments
- [ ] Notify all stakeholders
- [ ] Begin rollback process

### 2. Application Rollback
- [ ] Deploy previous application version
- [ ] Verify application deployment
- [ ] Clear caches if needed
- [ ] Restart services

### 3. Database Rollback
- [ ] Run rollback script (058)
- [ ] OR restore from backup
- [ ] Verify data integrity
- [ ] Test critical queries

### 4. Validation
- [ ] Verify application works
- [ ] Check error logs
- [ ] Test key user flows
- [ ] Confirm rollback successful

### 5. Post-Rollback
- [ ] Investigate root cause
- [ ] Document issues found
- [ ] Plan fixes
- [ ] Schedule re-deployment

---

## Success Criteria

Deployment is successful if ALL of the following are true:

### Technical Criteria
- [ ] All migrations executed without errors
- [ ] No data loss or corruption
- [ ] Error rate <1%
- [ ] API response times <500ms
- [ ] Database queries <100ms
- [ ] No critical bugs

### User Experience Criteria
- [ ] Users can create budgets
- [ ] Users can view budgets
- [ ] Calculated totals display correctly
- [ ] Virtual category works (personal view)
- [ ] System category badge visible
- [ ] No user complaints

### Business Criteria
- [ ] All features working as designed
- [ ] No revenue impact
- [ ] Support ticket volume normal
- [ ] User engagement normal
- [ ] Stakeholder approval

---

## Contact Information

### Deployment Team
- **Technical Lead:** [Name] - [Contact]
- **Database Admin:** [Name] - [Contact]
- **DevOps:** [Name] - [Contact]
- **QA Lead:** [Name] - [Contact]

### Escalation Path
1. Technical Lead
2. Engineering Manager
3. CTO
4. Incident Commander (if critical)

### Emergency Contacts
- **On-Call Engineer:** [Contact]
- **Database Emergency:** [Contact]
- **Incident Hotline:** [Contact]

---

## Deployment Log

```
Date: _______________
Time: _______________
Deployed By: _______________
Environment: Production

Phase 1 - Preparation: [✓ Complete / ✗ Incomplete]
Phase 2 - Staging: [✓ Complete / ✗ Incomplete]
Phase 3 - Strategy: [Method chosen: _____]
Phase 4 - Deployment: [✓ Success / ✗ Failed]
Phase 5 - Monitoring: [✓ All Clear / ⚠ Issues Found]
Phase 6 - Rollout: [N/A / In Progress / Complete]
Phase 7 - Post-Deploy: [✓ Complete / In Progress]

Issues Found:
1. _______________________________
2. _______________________________
3. _______________________________

Resolution:
_________________________________
_________________________________

Rollback Required: [Yes / No]
If Yes, Reason: ___________________

Final Status: [✓ Success / ✗ Failed / ↩ Rolled Back]

Sign-Off:
- Technical Lead: _______________ Date: _______
- Product Owner: _______________ Date: _______
- QA Lead: _______________ Date: _______
```

---

## Appendix: Quick Reference Commands

### Backup Database
```bash
supabase db dump -f backup_prod_$(date +%Y%m%d_%H%M%S).sql
```

### Run Migrations
```bash
supabase db push --file supabase/migrations/052_deprecate_manual_budgets.sql
# ... repeat for 053-057
```

### Check Migration Status
```sql
SELECT * FROM supabase_migrations.schema_migrations
ORDER BY version DESC LIMIT 10;
```

### Monitor Error Logs
```bash
tail -f /var/log/app/error.log
```

### Check Database Performance
```sql
SELECT * FROM pg_stat_statements
ORDER BY total_exec_time DESC LIMIT 10;
```

### Rollback
```bash
supabase db push --file supabase/migrations/058_rollback_category_only_budgets.sql
# OR
supabase db restore backup_prod_YYYYMMDD_HHMMSS.sql
```

---

**Document Version:** 1.0
**Last Updated:** 2026-01-08
**Author:** Claude Sonnet 4.5
**Status:** Ready for use
