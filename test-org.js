const { chromium } = require('playwright');

async function testOrganizationCreation() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
  const page = await context.newPage();

  // Enable console logging
  page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  page.on('pageerror', err => console.error('PAGE ERROR:', err.message));

  try {
    console.log('1. Navigating to app...');
    await page.goto('http://localhost:4200/#/passport/login', { waitUntil: 'networkidle' });
    await page.screenshot({ path: '/tmp/01-login-page.png' });
    console.log('Screenshot: /tmp/01-login-page.png');

    console.log('2. Logging in...');
    // Wait for login form elements - using correct formControlName
    await page.waitForSelector('input[formcontrolname="email"]', { timeout: 10000 });
    await page.fill('input[formcontrolname="email"]', 'ac7x@pm.me');
    await page.fill('input[formcontrolname="password"]', '123123');
    await page.screenshot({ path: '/tmp/02-filled-login.png' });
    console.log('Screenshot: /tmp/02-filled-login.png');

    // Click login button
    await page.click('button[nz-button][type="submit"]');
    console.log('3. Waiting for redirect after login...');
    
    // Wait for navigation or dashboard page
    await page.waitForTimeout(5000);
    await page.screenshot({ path: '/tmp/03-after-login.png' });
    console.log('Screenshot: /tmp/03-after-login.png');

    // Check current URL
    console.log('Current URL:', page.url());

    // Click user avatar dropdown
    console.log('4. Looking for header components...');
    await page.waitForTimeout(2000);
    
    // Look for the header user component - try different selectors
    const selectors = [
      '.alain-default__header-item',
      'header-user',
      'nz-avatar',
      '.header-user',
      '[nz-dropdown]',
      'app-header-user',
      '.ant-avatar'
    ];
    
    for (const selector of selectors) {
      const element = page.locator(selector);
      const count = await element.count();
      console.log(`Selector "${selector}" found: ${count} element(s)`);
    }

    // Take a screenshot of current state
    await page.screenshot({ path: '/tmp/04-current-state.png' });
    console.log('Screenshot: /tmp/04-current-state.png');

    // Try clicking avatar
    const avatar = page.locator('nz-avatar').first();
    if (await avatar.count() > 0) {
      console.log('5. Clicking avatar...');
      await avatar.click();
      await page.waitForTimeout(1000);
      await page.screenshot({ path: '/tmp/05-after-avatar-click.png' });
      console.log('Screenshot: /tmp/05-after-avatar-click.png');
    }

    // Look for create organization option
    const createOrgButton = page.locator('text=建立組織');
    if (await createOrgButton.count() > 0) {
      console.log('6. Found create organization button, clicking...');
      await createOrgButton.click();
      await page.waitForTimeout(1000);
      await page.screenshot({ path: '/tmp/06-create-org-dialog.png' });
      console.log('Screenshot: /tmp/06-create-org-dialog.png');
    } else {
      console.log('Create organization button not found');
    }

  } catch (error) {
    console.error('Error:', error);
    await page.screenshot({ path: '/tmp/error.png' });
    console.log('Error screenshot: /tmp/error.png');
  } finally {
    await browser.close();
  }
}

testOrganizationCreation().catch(console.error);
