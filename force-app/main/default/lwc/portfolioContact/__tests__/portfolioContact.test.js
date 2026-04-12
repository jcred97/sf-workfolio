import { createElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import PortfolioContact from 'c/portfolioContact';
import submitLead from '@salesforce/apex/PortfolioController.submitLead';

jest.mock(
    'lightning/uiRecordApi',
    () => {
        const {
            createLdsTestWireAdapter
        } = require('@salesforce/wire-service-jest-util');

        return {
            getRecord: createLdsTestWireAdapter(jest.fn()),
            getFieldValue: jest.fn((record, field) => {
                const fieldName =
                    typeof field === 'string'
                        ? field.split('.').pop()
                        : field?.fieldApiName || field?.fieldName;

                return record?.fields?.[fieldName]?.value;
            })
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/PortfolioController.submitLead',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

const mockPortfolioRecord = {
    fields: {
        Email__c: {
            value: 'portfolio@example.com'
        }
    }
};

const flushPromises = () => Promise.resolve();

function createComponent() {
    const element = createElement('c-portfolio-contact', {
        is: PortfolioContact
    });
    element.recordId = 'a00000000000001AAA';
    document.body.appendChild(element);
    getRecord.emit(mockPortfolioRecord);
    return element;
}

function mockFieldValidation(element, results) {
    const fields = Array.from(
        element.shadowRoot.querySelectorAll('input, textarea')
    );

    fields.forEach((field, index) => {
        field.setCustomValidity = jest.fn();
        field.reportValidity = jest.fn();
        field.checkValidity = jest.fn(() => results[index]);
    });

    return fields;
}

describe('c-portfolio-contact', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }

        jest.clearAllMocks();
    });

    it('blocks submission when the form is invalid', async () => {
        const element = createComponent();
        mockFieldValidation(element, [true, false, true, true]);

        element.shadowRoot.querySelector('button').click();
        await flushPromises();

        expect(submitLead).not.toHaveBeenCalled();
    });

    it('submits trimmed valid form data and shows success state', async () => {
        submitLead.mockResolvedValue({});

        const element = createComponent();
        const [firstNameInput, lastNameInput, emailInput, messageInput] =
            mockFieldValidation(element, [true, true, true, true]);

        firstNameInput.value = ' John ';
        firstNameInput.dispatchEvent(new CustomEvent('change'));

        lastNameInput.value = ' Doe ';
        lastNameInput.dispatchEvent(new CustomEvent('change'));

        emailInput.value = ' john@example.com ';
        emailInput.dispatchEvent(new CustomEvent('change'));

        messageInput.value = ' Hello there ';
        messageInput.dispatchEvent(new CustomEvent('change'));

        element.shadowRoot.querySelector('button').click();
        await flushPromises();
        await flushPromises();

        expect(submitLead).toHaveBeenCalledTimes(1);
        expect(submitLead).toHaveBeenCalledWith({
            firstName: 'John',
            lastName: 'Doe',
            emailAddress: 'john@example.com',
            message: 'Hello there'
        });
        const successBanner =
            element.shadowRoot.querySelector('.success-banner');
        expect(successBanner.textContent).toContain(
            'Message sent successfully'
        );
        expect(lastNameInput.value).toBe('');
        expect(emailInput.value).toBe('');
        expect(messageInput.value).toBe('');
    });
});
