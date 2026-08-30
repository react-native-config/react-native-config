/**
 * @format
 */

import React from 'react';
import ReactTestRenderer from 'react-test-renderer';
import App from '../App';

test('renders the config values', async () => {
  let tree!: ReactTestRenderer.ReactTestRenderer;
  await ReactTestRenderer.act(() => {
    tree = ReactTestRenderer.create(<App />);
  });

  const rendered = JSON.stringify(tree.toJSON());
  expect(rendered).toContain('ENV=');
  expect(rendered).toContain('dev');
  expect(rendered).toContain('API_URL=');
  expect(rendered).toContain('http://localhost');
});
