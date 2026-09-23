import { test } from 'node:test';
import assert from 'node:assert/strict';
import { decidePremiumUpdate } from './revenuecatWebhook';

test('decidePremiumUpdate: 購入・更新系イベントはtrue(付与)を返す', () => {
  assert.equal(decidePremiumUpdate('INITIAL_PURCHASE'), true);
  assert.equal(decidePremiumUpdate('RENEWAL'), true);
  assert.equal(decidePremiumUpdate('UNCANCELLATION'), true);
  assert.equal(decidePremiumUpdate('PRODUCT_CHANGE'), true);
});

test('decidePremiumUpdate: EXPIRATIONはfalse(剥奪)を返す', () => {
  assert.equal(decidePremiumUpdate('EXPIRATION'), false);
});

test('decidePremiumUpdate: CANCELLATIONは即座には失効しないためnull(無視)を返す', () => {
  assert.equal(decidePremiumUpdate('CANCELLATION'), null);
});

test('decidePremiumUpdate: 未知のイベント種別はnull(無視)を返す', () => {
  assert.equal(decidePremiumUpdate('BILLING_ISSUE'), null);
  assert.equal(decidePremiumUpdate('SUBSCRIPTION_PAUSED'), null);
  assert.equal(decidePremiumUpdate('TRANSFER'), null);
});
